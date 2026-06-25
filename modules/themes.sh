#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

backup_themes() {

    local backup_root="$1"
    local target="$backup_root/themes"

    ensure_directory "$target"

    info "Backing up GTK themes..."

    local dirs=(
        "$HOME/.themes"
        "$HOME/.local/share/themes"
    )

    for dir in "${dirs[@]}"; do

        if [[ -d "$dir" ]]; then

            rsync -aHAX "$dir/" "$target/"

            success "Backed up: $dir"

        fi

    done
}
