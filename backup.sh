#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/modules/packages.sh"
source "$PROJECT_ROOT/modules/dotfiles.sh"

if [[ $# -ne 1 ]]; then
    echo "Usage:"
    echo "  ./backup.sh <backup-directory>"
    exit 1
fi

BACKUP_ROOT="$1"

ensure_directory "$BACKUP_ROOT"

init_logger "$BACKUP_ROOT"

info "Starting ArchForge backup..."

generate_manifest "$BACKUP_ROOT"

export_packages "$BACKUP_ROOT"

backup_dotfiles "$BACKUP_ROOT"

success "Backup completed successfully."
