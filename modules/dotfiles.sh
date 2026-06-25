#!/usr/bin/env bash

# ==========================================================
# ArchForge Dotfiles Backup
# ==========================================================

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logging.sh"

backup_dotfiles() {

    local backup_root="$1"

    local target="$backup_root/dotfiles"

    ensure_directory "$target"

    require_command rsync

    info "Backing up user configuration..."

    rsync -aHAX \
        --delete \
        --exclude-from="$PROJECT_ROOT/config/exclude.conf" \
        "$HOME/.config/" \
        "$target/.config/"

    success ".config backed up"

    local dotfiles=(
        ".zshrc"
        ".bashrc"
        ".profile"
        ".gitconfig"
        ".tmux.conf"
        ".xinitrc"
        ".Xresources"
    )

    for file in "${dotfiles[@]}"; do

        if file_exists "$HOME/$file"; then

            rsync -a "$HOME/$file" "$target/"

            success "$file backed up"

        fi

    done
}
