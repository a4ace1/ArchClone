#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/lib/banner.sh"
show_banner

source "$PROJECT_ROOT/lib/common.sh"

usage() {
cat <<EOF
Usage:
  ./verify.sh <backup-directory-or-archive>

Verifies the integrity of an ArchClone backup by checking its
SHA-256 checksums (checksums.sha256) and confirming a valid
manifest.json is present. Accepts either an extracted backup
directory or a compressed archive (.tar.zst / .tar.gz / .tgz / .tar).
EOF
}

if [[ $# -ne 1 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 1
fi

INPUT="$1"

TMP_EXTRACT_DIR=""
cleanup() {
    if [[ -n "$TMP_EXTRACT_DIR" && -d "$TMP_EXTRACT_DIR" ]]; then
        rm -rf "$TMP_EXTRACT_DIR"
    fi
}
trap cleanup EXIT

if [[ -d "$INPUT" ]]; then
    BACKUP_ROOT="$INPUT"
elif is_archive_file "$INPUT"; then
    TMP_EXTRACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/archclone-verify.XXXXXX")"
    extract_archive "$INPUT" "$TMP_EXTRACT_DIR"
    BACKUP_ROOT="$(find_backup_root "$TMP_EXTRACT_DIR")"
else
    die "Not a valid backup directory or archive: $INPUT"
fi

init_logger "$BACKUP_ROOT"

if [[ ! -f "$BACKUP_ROOT/manifest.json" ]]; then
    die "manifest.json missing — '$BACKUP_ROOT' doesn't look like an ArchClone backup."
fi
success "manifest.json present."

if [[ ! -f "$BACKUP_ROOT/checksums.sha256" ]]; then
    die "checksums.sha256 missing — cannot verify integrity."
fi

verify_checksums "$BACKUP_ROOT"

success "Backup verified successfully: $INPUT"
