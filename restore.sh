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
  <backup-directory-or-archive>   Either an extracted ArchForge backup
                                   directory, or a compressed archive
                                   produced by 'backup.sh' (.tar.zst,
                                   .tar.gz/.tgz, or .tar).

Options:
  -y, --yes       Assume "yes" to the restore confirmation prompt.
                   Equivalent to setting ARCHFORGE_YES=1. Required for
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

if [[ "${ARCHFORGE_YES:-0}" == "1" ]]; then
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
    TMP_EXTRACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/archforge-restore.XXXXXX")"
    extract_archive "$INPUT" "$TMP_EXTRACT_DIR"
    BACKUP_ROOT="$(find_backup_root "$TMP_EXTRACT_DIR")"
else
    die "Not a valid backup directory or archive: $INPUT"
fi

[[ -f "$BACKUP_ROOT/manifest.json" ]] \
    || die "No manifest.json found — '$BACKUP_ROOT' doesn't look like an ArchForge backup."

init_logger "$BACKUP_ROOT"

verify_checksums "$BACKUP_ROOT"

# --- Confirmation ---------------------------------------------------
#
# stdin-safety: archive extraction above always redirects its own
# stdin from /dev/null (see lib/archive.sh), so nothing before this
# point can have consumed input meant for the prompt below. Likewise,
# this is the *only* place stdin is read in the whole restore flow,
# so `yes | ./archforge restore backup.tar.zst` and interactive use
# both work correctly, and no downstream pipeline can steal the
# answer.
if [[ "$ASSUME_YES" != "1" ]]; then
    if [[ ! -t 0 && ! -p /dev/stdin ]]; then
        die "Restore requires confirmation but stdin is neither a terminal nor a pipe. Re-run with --yes (or ARCHFORGE_YES=1) for non-interactive/CI use."
    fi

    if ! confirm "This will overwrite files under '$TARGET_HOME'. Continue restoring from '$BACKUP_ROOT'?"; then
        die "Restore cancelled."
    fi
fi

export ARCHFORGE_TARGET_HOME="$TARGET_HOME"

load_restore_plugins

run_restore_plugins "$BACKUP_ROOT"

success "System restored successfully."
