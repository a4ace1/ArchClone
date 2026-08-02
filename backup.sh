#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/lib/banner.sh"
show_banner

usage() {
cat <<EOF
Usage:
  ./backup.sh <destination-directory>

Creates a new ArchClone backup and writes a single compressed
archive (archclone-<hostname>-<timestamp>.tar.zst, plus a .sha256
sidecar) into <destination-directory>.

All backup content is staged on a local filesystem first and only
the finished archive is ever written to <destination-directory> --
this makes backups work correctly on exFAT, FAT32, and NTFS drives,
which cannot store the symlinks, ownership, and extended attributes
ArchClone backups rely on. Nothing is extracted or partially written
directly onto <destination-directory> at any point.
EOF
}

if [[ $# -eq 0 ]]; then
    echo "Error: missing required <destination-directory> argument." >&2
    echo >&2
    usage >&2
    exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

if [[ $# -gt 1 ]]; then
    echo "Error: too many arguments." >&2
    echo >&2
    usage >&2
    exit 1
fi

DEST_DIR="$1"

if [[ -z "$DEST_DIR" ]]; then
    echo "Error: <destination-directory> cannot be empty." >&2
    exit 1
fi

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/plugin_loader.sh"

load_plugins

ensure_directory "$DEST_DIR"

if [[ ! -w "$DEST_DIR" ]]; then
    echo "Error: destination directory is not writable: $DEST_DIR" >&2
    exit 1
fi

# --- Staging: everything is built here first, on a local filesystem,
# regardless of what <destination-directory> is. Only the finished
# archive ever gets copied out to the destination. This is what makes
# exFAT/FAT32/NTFS destinations work: they never see the raw backup
# tree, symlinks and all -- they only ever see one opaque archive file.
STAGING_BASE="${ARCHCLONE_STAGING_DIR:-$HOME/.cache/archclone/staging}"
ensure_directory "$STAGING_BASE"
STAGING_ROOT="$(mktemp -d "$STAGING_BASE/run.XXXXXX")"
LOCAL_ARCHIVE="${STAGING_ROOT}.tar.zst"

# On any non-clean exit, report exactly what survived and where --
# never delete anything here. Cleanup only happens once, at the very
# end, after the destination copy has been verified.
STAGING_CLEANED=0
_report_on_failure() {
    local rc=$?
    if [[ "$STAGING_CLEANED" != "1" ]]; then
        echo >&2
        error "Backup did not complete successfully (exit $rc)."
        [[ -d "$STAGING_ROOT" ]] && error "Staged backup data preserved at: $STAGING_ROOT"
        [[ -f "$LOCAL_ARCHIVE" ]] && error "Locally built archive preserved at: $LOCAL_ARCHIVE"
    fi
}
trap _report_on_failure EXIT

init_logger "$STAGING_ROOT"

generate_manifest "$STAGING_ROOT"

run_backup_plugins "$STAGING_ROOT"

generate_checksums "$STAGING_ROOT"

create_archive \
    "$STAGING_ROOT" \
    "$LOCAL_ARCHIVE"

TIMESTAMP="$(date +%F-%H%M%S)"
HOSTNAME_RAW="$(discover_hostname)"
HOSTNAME_SAFE="$(printf '%s' "$HOSTNAME_RAW" | tr -c 'A-Za-z0-9._-' '_')"
ARCHIVE_NAME="archclone-${HOSTNAME_SAFE}-${TIMESTAMP}.tar.zst"
DEST_ARCHIVE="${DEST_DIR%/}/${ARCHIVE_NAME}"

# The sidecar's second column must be the name the file will actually
# have at the destination, not its temporary staging name -- otherwise
# `sha256sum -c` against the copied sidecar fails with "no such file"
# even when the archive is perfectly intact.
LOCAL_HASH="$(sha256sum "$LOCAL_ARCHIVE" | cut -d' ' -f1)"
echo "$LOCAL_HASH  $ARCHIVE_NAME" > "${LOCAL_ARCHIVE}.sha256"

info "Copying archive to destination..."
cp "$LOCAL_ARCHIVE" "$DEST_ARCHIVE"
cp "${LOCAL_ARCHIVE}.sha256" "${DEST_ARCHIVE}.sha256"

DEST_HASH="$(sha256sum "$DEST_ARCHIVE" | cut -d' ' -f1)"
if [[ "$DEST_HASH" != "$LOCAL_HASH" ]]; then
    error "Destination copy failed verification: hash mismatch."
    error "Expected: $LOCAL_HASH"
    error "Got:      $DEST_HASH"
    exit 1
fi
success "Destination copy verified."

# The one gated cleanup call: only reached after the destination copy
# has been hash-verified against the locally built archive.
rm -rf "$STAGING_ROOT"
rm -f "$LOCAL_ARCHIVE" "${LOCAL_ARCHIVE}.sha256"
STAGING_CLEANED=1
LOG_FILE=""  # was pointing inside the now-deleted staging dir; clear it
             # so any further logging prints to the console only,
             # instead of failing to append and masking a successful
             # exit behind set -e.

success "Backup completed successfully: $DEST_ARCHIVE"
