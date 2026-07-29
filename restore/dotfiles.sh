#!/usr/bin/env bash

# ==========================================================
# ArchForge Dotfiles Restore
# ==========================================================

set -Eeuo pipefail

restore_dotfiles() {

    local backup_root="$1"

    info "Restoring configuration..."

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
        if [[ -e "$backup_root/home/.config/$item" ]]; then
            rsync_restore_path ".config/$item" "$backup_root"
            success "Restored: .config/$item"
        fi
    done

    local dotfiles=(
        .zshrc
        .bashrc
        .profile
        .gitconfig
    )

    for file in "${dotfiles[@]}"; do
        if [[ -e "$backup_root/home/$file" ]]; then
            rsync_restore_path "$file" "$backup_root"
            success "Restored: $file"
        fi
    done
}
