#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/lib/common.sh"

if [[ $# -ne 1 ]]; then
    echo "Usage:"
    echo "  ./restore.sh <backup-directory>"
    exit 1
fi

BACKUP_ROOT="$1"

init_logger "$BACKUP_ROOT"

verify_checksums "$BACKUP_ROOT"

load_restore_plugins

run_restore_plugins "$BACKUP_ROOT"

success "System restored successfully."
