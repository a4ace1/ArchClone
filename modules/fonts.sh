#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

backup_fonts() {

    local backup_root="$1"
    local target="$backup_root/fonts"

    ensure_directory "$target"

    info "Backing up fonts..."

    local dirs=(
        "$HOME/.local/share/fonts"
        "$HOME/.fonts"
    )

    for dir in "${dirs[@]}"; do

        if [[ -d "$dir" ]]; then

            rsync -aHAX "$dir/" "$target/"

            success "Backed up: $dir"
        fi

    done
}
