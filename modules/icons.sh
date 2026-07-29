#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

backup_icons() {

    local backup_root="$1"

    info "Backing up icon themes..."

    local dirs
    mapfile -t dirs < <(discover_icons)

    for dir in "${dirs[@]}"; do
        [[ -n "$dir" ]] || continue
        rsync_backup_path "$dir" "$backup_root"
        success "Backed up: $dir"
    done
}
