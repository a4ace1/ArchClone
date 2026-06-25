#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

backup_icons() {

    local backup_root="$1"
    local target="$backup_root/icons"

    ensure_directory "$target"

    info "Backing up icon themes..."

    local dirs=(
        "$HOME/.icons"
        "$HOME/.local/share/icons"
    )

    for dir in "${dirs[@]}"; do

        if [[ -d "$dir" ]]; then

            rsync -aHAX "$dir/" "$target/"

            success "Backed up: $dir"

        fi

    done
}
