#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

backup_themes() {

    local backup_root="$1"

    info "Backing up GTK themes..."

    local dirs
    mapfile -t dirs < <(discover_themes)

    for dir in "${dirs[@]}"; do
        [[ -n "$dir" ]] || continue
        rsync_backup_path "$dir" "$backup_root"
        success "Backed up: $dir"
    done
}
