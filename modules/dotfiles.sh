#!/usr/bin/env bash

# ==========================================================
# ArchForge Dotfiles Backup
# ==========================================================

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

backup_dotfiles() {

    local backup_root="$1"
    local target="$backup_root/dotfiles"

    ensure_directory "$target"

    require_command rsync

    info "Backing up configuration..."

    local configs=(
        hypr
        waybar
        rofi
        alacritty
        kitty
        fastfetch
        mpv
        dunst
        swaync
        gtk-3.0
        gtk-4.0
        zathura
        qt5ct
        qt6ct
        mimeapps.list
    )

    for item in "${configs[@]}"; do

        local src="$HOME/.config/$item"

        if [[ -e "$src" ]]; then

            rsync -aHAX "$src" "$target/"

            success "Backed up: $item"

        fi

    done

    local dotfiles=(
        .zshrc
        .bashrc
        .profile
        .gitconfig
    )

    for file in "${dotfiles[@]}"; do

        if [[ -f "$HOME/$file" ]]; then

            rsync -a "$HOME/$file" "$target/"

            success "Backed up: $file"

        fi

    done
}
   
