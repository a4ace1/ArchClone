#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

backup_wallpapers() {

    local backup_root="$1"

    info "Backing up wallpapers..."

    while IFS= read -r dir; do
        [[ -n "$dir" && -d "$dir" ]] || continue
        rsync_backup_path "$dir" "$backup_root"
        success "Backed up: $dir"
    done < <(discover_wallpapers)
}
