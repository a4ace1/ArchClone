#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

backup_fonts() {

    local backup_root="$1"

    info "Backing up fonts..."

    local dirs
    mapfile -t dirs < <(discover_fonts)

    for dir in "${dirs[@]}"; do
        [[ -n "$dir" ]] || continue
        rsync_backup_path "$dir" "$backup_root"
        success "Backed up: $dir"
    done
}
