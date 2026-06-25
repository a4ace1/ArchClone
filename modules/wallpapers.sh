#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

backup_wallpapers() {

    local backup_root="$1"
    local target="$backup_root/wallpapers"

    ensure_directory "$target"

    info "Backing up wallpapers..."

    while IFS= read -r dir; do

        [[ -d "$dir" ]] || continue

        rsync -aHAX "$dir/" "$target/"

        success "Backed up: $dir"

    done < <(discover_wallpapers)
}
