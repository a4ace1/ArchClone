#!/usr/bin/env bash

# ==========================================================
# ArchClone Dotfiles Backup
# ==========================================================

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

backup_dotfiles() {

    local backup_root="$1"

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
            rsync_backup_path "$src" "$backup_root"
            success "Backed up: .config/$item"
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
            rsync_backup_path "$HOME/$file" "$backup_root"
            success "Backed up: $file"
        fi

    done
}
