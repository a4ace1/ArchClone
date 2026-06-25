#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/lib/common.sh"

source "$PROJECT_ROOT/modules/wallpapers.sh"

load_plugins

BACKUP_ROOT="$1"

ensure_directory "$BACKUP_ROOT"

init_logger "$BACKUP_ROOT"

generate_manifest "$BACKUP_ROOT"

run_backup_plugins "$BACKUP_ROOT"

success "Backup completed successfully."
