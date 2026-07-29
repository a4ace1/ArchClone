#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/lib/banner.sh"
show_banner

usage() {
cat <<EOF
Usage:
  ./backup.sh <backup-directory>

Creates a new ArchForge backup under <backup-directory> and produces
a compressed <backup-directory>-<timestamp>.tar.zst archive next to it.
EOF
}

if [[ $# -eq 0 ]]; then
    echo "Error: missing required <backup-directory> argument." >&2
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

BACKUP_ROOT="$1"

if [[ -z "$BACKUP_ROOT" ]]; then
    echo "Error: <backup-directory> cannot be empty." >&2
    exit 1
fi

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/plugin_loader.sh"

load_plugins

ensure_directory "$BACKUP_ROOT"

init_logger "$BACKUP_ROOT"

generate_manifest "$BACKUP_ROOT"

run_backup_plugins "$BACKUP_ROOT"

generate_checksums "$BACKUP_ROOT"

TIMESTAMP="$(date +%F-%H%M%S)"

create_archive \
    "$BACKUP_ROOT" \
    "${BACKUP_ROOT}-${TIMESTAMP}.tar.zst"

success "Backup completed successfully."
