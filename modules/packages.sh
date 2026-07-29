#!/usr/bin/env bash

# ==========================================================
# ArchForge Package Inventory
# ==========================================================

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# _archforge_pip_cmd
#
# Prefers `pip3` (the canonical name on most modern distros,
# including Arch) but falls back to `pip` if that's all that's
# available. Prints nothing if neither exists.
_archforge_pip_cmd() {
    if command_exists pip3; then
        echo "pip3"
    elif command_exists pip; then
        echo "pip"
    fi
}

backup_packages() {

    local outdir="$1/packages"

    ensure_directory "$outdir"

    info "Exporting package inventory..."

    # Pacman
    if command_exists pacman; then
        if pacman -Qqe > "$outdir/pacman.txt.tmp" 2>/dev/null; then
            sort -o "$outdir/pacman.txt" "$outdir/pacman.txt.tmp"
            rm -f "$outdir/pacman.txt.tmp"
            success "Pacman packages exported"
        else
            rm -f "$outdir/pacman.txt.tmp"
            warn "Failed to export pacman packages"
        fi
    fi

    # AUR (yay)
    if command_exists yay; then
        if yay -Qqm > "$outdir/aur.txt.tmp" 2>/dev/null; then
            sort -o "$outdir/aur.txt" "$outdir/aur.txt.tmp"
            rm -f "$outdir/aur.txt.tmp"
            success "AUR packages exported"
        else
            rm -f "$outdir/aur.txt.tmp"
            warn "Failed to export AUR packages"
        fi
    fi

    # Flatpak
    if command_exists flatpak; then
        if flatpak list --app --columns=application 2>/dev/null | sort > "$outdir/flatpak.txt"; then
            success "Flatpak packages exported"
        else
            warn "Failed to export Flatpak packages"
        fi
    fi

    # npm
    if command_exists npm; then
        if npm list -g --depth=0 2>/dev/null | tail -n +2 | awk '{print $2}' | grep -v '^$' > "$outdir/npm.txt"; then
            success "npm packages exported"
        else
            # npm list can exit non-zero on peer-dependency warnings even
            # though it still printed useful output; only warn if we
            # ended up with nothing at all.
            if [[ ! -s "$outdir/npm.txt" ]]; then
                warn "Failed to export npm packages"
            else
                success "npm packages exported"
            fi
        fi
    fi

    # pip / pip3 (prefer pip3; fall back to pip)
    local pip_cmd
    pip_cmd="$(_archforge_pip_cmd)"
    if [[ -n "$pip_cmd" ]]; then
        if "$pip_cmd" list --format=freeze > "$outdir/pip.txt" 2>/dev/null; then
            success "pip packages exported (via $pip_cmd)"
        else
            warn "Failed to export pip packages"
        fi
    fi

    # pipx
    if command_exists pipx; then
        if pipx list --short > "$outdir/pipx.txt" 2>/dev/null; then
            success "pipx packages exported"
        else
            warn "Failed to export pipx packages"
        fi
    fi

    # Cargo
    if command_exists cargo; then
        if cargo install --list 2>/dev/null | awk -F' ' '/ v/ {print $1}' > "$outdir/cargo.txt"; then
            success "Cargo packages exported"
        else
            warn "Failed to export Cargo packages"
        fi
    fi
}
