#!/usr/bin/env bash

set -Eeuo pipefail


restore_packages() {

    local backup_root="$1"
    local pkg_dir="$backup_root/packages"

    [[ -d "$pkg_dir" ]] || die "Package backup not found."

    info "Restoring package inventory..."

    if [[ -f "$pkg_dir/pacman.txt" ]]; then
        info "Pacman package list found."
        echo "sudo pacman -S --needed - < $pkg_dir/pacman.txt"
    fi

    if [[ -f "$pkg_dir/aur.txt" ]]; then
        info "AUR package list found."
    fi

    if [[ -f "$pkg_dir/flatpak.txt" ]]; then
        info "Flatpak package list found."
    fi

    if [[ -f "$pkg_dir/npm.txt" ]]; then
        info "npm package list found."
    fi

    if [[ -f "$pkg_dir/pip.txt" ]]; then
        info "pip package list found."
    fi

    if [[ -f "$pkg_dir/pipx.txt" ]]; then
        info "pipx package list found."
    fi

    success "Restore discovery completed."
}
