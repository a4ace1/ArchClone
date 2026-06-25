#!/usr/bin/env bash

# ==========================================================
# ArchForge Package Inventory
# ==========================================================

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logging.sh"

export_packages() {

    local outdir="$1/packages"

    ensure_directory "$outdir"

    info "Exporting package inventory..."

    # Pacman
    if command_exists pacman; then
        pacman -Qqe | sort > "$outdir/pacman.txt"
        success "Pacman packages exported"
    fi

    # AUR (yay)
    if command_exists yay; then
        yay -Qqm | sort > "$outdir/aur.txt"
        success "AUR packages exported"
    fi

    # Flatpak
    if command_exists flatpak; then
        flatpak list --app --columns=application \
            | sort > "$outdir/flatpak.txt"
        success "Flatpak packages exported"
    fi

    # npm
    if command_exists npm; then
        npm list -g --depth=0 \
            | tail -n +2 \
            | awk '{print $2}' \
            > "$outdir/npm.txt"

        success "npm packages exported"
    fi

    # pip
    if command_exists pip; then
        pip list --format=freeze \
            > "$outdir/pip.txt"

        success "pip packages exported"
    fi

    # pipx
    if command_exists pipx; then
        pipx list --short \
            > "$outdir/pipx.txt"

        success "pipx packages exported"
    fi

    # Cargo
    if command_exists cargo; then
        cargo install --list \
            | awk -F' ' '/ v/ {print $1}' \
            > "$outdir/cargo.txt"

        success "Cargo packages exported"
    fi
}
