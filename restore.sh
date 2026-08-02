#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/lib/banner.sh"
show_banner

source "$PROJECT_ROOT/lib/common.sh"

usage() {
cat <<EOF
Usage:
  ./restore.sh <backup-directory-or-archive> [options]

Arguments:
  <backup-directory-or-archive>   Either an extracted ArchClone backup
                                   directory, or a compressed archive
                                   produced by 'backup.sh' (.tar.zst,
                                   .tar.gz/.tgz, or .tar).

Options:
  -y, --yes       Assume "yes" to the restore confirmation prompt.
                   Equivalent to setting ARCHCLONE_YES=1. Required for
                   non-interactive/CI use.
  --home <dir>    Restore into <dir> instead of \$HOME.
  -h, --help      Show this help and exit.
EOF
}

ASSUME_YES=0
TARGET_HOME="$HOME"
INPUT=""

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)
            ASSUME_YES=1
            shift
            ;;
        --home)
            [[ $# -ge 2 ]] || die "--home requires an argument"
            TARGET_HOME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
        *)
            if [[ -n "$INPUT" ]]; then
                echo "Unexpected extra argument: $1" >&2
                usage
                exit 1
            fi
            INPUT="$1"
            shift
            ;;
    esac
done

if [[ -z "$INPUT" ]]; then
    echo "Error: missing backup directory or archive." >&2
    usage
    exit 1
fi

if [[ "${ARCHCLONE_YES:-0}" == "1" ]]; then
    ASSUME_YES=1
fi

TMP_EXTRACT_DIR=""
cleanup() {
    if [[ -n "$TMP_EXTRACT_DIR" && -d "$TMP_EXTRACT_DIR" ]]; then
        rm -rf "$TMP_EXTRACT_DIR"
    fi
}
trap cleanup EXIT

# --- Resolve input: accept either an extracted directory or an archive ---
if [[ -d "$INPUT" ]]; then
    BACKUP_ROOT="$INPUT"
elif is_archive_file "$INPUT"; then
    # Default extraction base: under $HOME rather than bare /tmp.
    # /tmp is frequently tmpfs-backed (RAM), which both limits how large
    # a backup can be restored and competes with the system's actual
    # memory -- $HOME is far more likely to have real disk space, and is
    # where the restored files are headed anyway. Still overridable for
    # anyone who genuinely wants /tmp or another location.
    EXTRACT_BASE="${ARCHCLONE_RESTORE_TMPDIR:-$HOME/.cache/archclone/restore}"
    ensure_directory "$EXTRACT_BASE"

    # Free-space check before extraction (previously: none at all --
    # extraction would run and fail partway through on a full disk,
    # with tar's own error as the only diagnostic). 1.15x safety margin
    # over the estimated uncompressed size accounts for tar block
    # padding and the estimate's inherent approximation.
    ARCHIVE_SIZE_BYTES="$(stat -c%s "$INPUT" 2>/dev/null || echo 0)"
    ESTIMATED_BYTES="$(estimate_archive_uncompressed_size "$INPUT")"
    if [[ -z "$ESTIMATED_BYTES" || "$ESTIMATED_BYTES" -eq 0 ]]; then
        # Estimation failed or the archive is empty/unreadable -- fall
        # back to a conservative multiple of the compressed size rather
        # than skipping the check entirely.
        ESTIMATED_BYTES=$((ARCHIVE_SIZE_BYTES * 4))
    fi
    REQUIRED_BYTES=$(( ESTIMATED_BYTES + ESTIMATED_BYTES * 15 / 100 ))

    if ! check_free_space "$EXTRACT_BASE" "$REQUIRED_BYTES"; then
        AVAIL_KB="$(df -Pk "$EXTRACT_BASE" 2>/dev/null | awk 'NR==2 {print $4}')"
        AVAIL_HUMAN="$( [[ -n "$AVAIL_KB" ]] && human_size $((AVAIL_KB * 1024)) || echo "unknown" )"
        die "Not enough free space to extract this backup.
  Extraction target: $EXTRACT_BASE
  Filesystem:        $(describe_path_filesystem "$EXTRACT_BASE")
  Estimated need:     ~$(human_size "$REQUIRED_BYTES") (archive is $(human_size "$ARCHIVE_SIZE_BYTES") compressed)
  Available:          $AVAIL_HUMAN
  Set ARCHCLONE_RESTORE_TMPDIR to a location with more free space and retry."
    fi

    TMP_EXTRACT_DIR="$(mktemp -d "$EXTRACT_BASE/run.XXXXXX")"
    extract_archive "$INPUT" "$TMP_EXTRACT_DIR" \
        || die "Extraction failed.
  Archive:    $INPUT
  Target:     $TMP_EXTRACT_DIR
  Filesystem: $(describe_path_filesystem "$TMP_EXTRACT_DIR")"
    BACKUP_ROOT="$(find_backup_root "$TMP_EXTRACT_DIR")"
else
    die "Not a valid backup directory or archive: $INPUT"
fi

[[ -f "$BACKUP_ROOT/manifest.json" ]] \
    || die "No manifest.json found at '$BACKUP_ROOT/manifest.json' -- '$BACKUP_ROOT' doesn't look like an ArchClone backup."

init_logger "$BACKUP_ROOT"

verify_checksums "$BACKUP_ROOT"

# --- Confirmation ---------------------------------------------------
#
# stdin-safety: archive extraction above always redirects its own
# stdin from /dev/null (see lib/archive.sh), so nothing before this
# point can have consumed input meant for the prompt below. Likewise,
# this is the *only* place stdin is read in the whole restore flow,
# so `yes | ./archclone restore backup.tar.zst` and interactive use
# both work correctly, and no downstream pipeline can steal the
# answer.
if [[ "$ASSUME_YES" != "1" ]]; then
    if [[ ! -t 0 && ! -p /dev/stdin ]]; then
        die "Restore requires confirmation but stdin is neither a terminal nor a pipe. Re-run with --yes (or ARCHCLONE_YES=1) for non-interactive/CI use."
    fi

    if ! confirm "This will overwrite files under '$TARGET_HOME'. Continue restoring from '$BACKUP_ROOT'?"; then
        die "Restore cancelled."
    fi
fi

export ARCHCLONE_TARGET_HOME="$TARGET_HOME"

load_restore_plugins

run_restore_plugins "$BACKUP_ROOT"

# --- Post-restore validation and summary ---------------------------
#
# run_restore_plugins succeeding only means each restore_* function
# returned 0 -- it says nothing about whether the expected content
# actually landed under $TARGET_HOME. This does a best-effort,
# category-level comparison (it doesn't need per-plugin knowledge of
# *how* each category restores, only that "$BACKUP_ROOT/<category>"
# existing implies something should now exist under $TARGET_HOME).
echo
info "Verifying restored content..."
RESTORE_ISSUES=0
for category_path in "$BACKUP_ROOT"/*; do
    [[ -d "$category_path" ]] || continue
    category="$(basename "$category_path")"

    case "$category" in
        home)
            # home/ mirrors dotfiles restored directly into $TARGET_HOME;
            # spot-check that at least one backed-up file exists there.
            SAMPLE_FILE="$(find "$category_path" -type f -print -quit)"
            if [[ -n "$SAMPLE_FILE" ]]; then
                REL_PATH="${SAMPLE_FILE#"$category_path"/}"
                if [[ -e "$TARGET_HOME/$REL_PATH" ]]; then
                    success "dotfiles: restored (verified $REL_PATH)"
                else
                    error "dotfiles: expected '$TARGET_HOME/$REL_PATH' after restore, not found"
                    RESTORE_ISSUES=$((RESTORE_ISSUES + 1))
                fi
            fi
            ;;
        packages)
            COUNT="$(find "$category_path" -type f | wc -l)"
            success "packages: $COUNT package list(s) available for manual review (not auto-installed)"
            ;;
        *)
            COUNT="$(find "$category_path" -type f | wc -l)"
            info "$category: $COUNT file(s) present in backup"
            ;;
    esac
done

echo
if [[ "$RESTORE_ISSUES" -eq 0 ]]; then
    success "Restore summary: all verifiable categories restored successfully."
    success "System restored successfully."
else
    error "Restore summary: $RESTORE_ISSUES categor$([ "$RESTORE_ISSUES" -eq 1 ] && echo y || echo ies) failed verification -- review the output above."
    exit 1
fi
