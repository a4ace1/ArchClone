#!/usr/bin/env bash

# ==========================================================
# ArchForge Package Restore
#
# Unlike the original stub, this module actually performs the
# restoration (installs the packages) instead of merely printing
# the commands a user could run. Each package manager is only
# invoked if it is present on the system, and the whole step is
# skippable via ARCHFORGE_SKIP_PACKAGES=1 for environments where
# reinstalling system packages isn't desired (e.g. CI, containers).
# ==========================================================

set -Eeuo pipefail

restore_packages() {

    local backup_root="$1"
    local pkg_dir="$backup_root/packages"

    if [[ ! -d "$pkg_dir" ]]; then
        warn "No package inventory found in backup, skipping."
        return 0
    fi

    if [[ "${ARCHFORGE_SKIP_PACKAGES:-0}" == "1" ]]; then
        warn "ARCHFORGE_SKIP_PACKAGES=1 set, skipping package restoration."
        return 0
    fi

    info "Restoring packages..."

    # Pacman
    if [[ -s "$pkg_dir/pacman.txt" ]]; then
        if command_exists pacman; then
            info "Installing pacman packages..."
            if command_exists sudo; then
                # Intentional: the `<` redirect is set up by this
                # (unprivileged) shell before sudo runs, which is the
                # standard/correct way to feed a file into a sudo'd
                # command's stdin.
                # shellcheck disable=SC2024
                if sudo pacman -S --needed --noconfirm - < "$pkg_dir/pacman.txt"; then
                    success "Pacman packages restored"
                else
                    warn "Some pacman packages failed to install"
                fi
            else
                warn "sudo not available; run manually: pacman -S --needed - < $pkg_dir/pacman.txt"
            fi
        else
            warn "pacman not found on this system; skipping $pkg_dir/pacman.txt"
        fi
    fi

    # AUR (yay)
    if [[ -s "$pkg_dir/aur.txt" ]]; then
        if command_exists yay; then
            info "Installing AUR packages..."
            if yay -S --needed --noconfirm - < "$pkg_dir/aur.txt"; then
                success "AUR packages restored"
            else
                warn "Some AUR packages failed to install"
            fi
        else
            warn "yay not found; skipping $pkg_dir/aur.txt"
        fi
    fi

    # Flatpak
    if [[ -s "$pkg_dir/flatpak.txt" ]]; then
        if command_exists flatpak; then
            info "Installing Flatpak packages..."
            while IFS= read -r app; do
                [[ -n "$app" ]] || continue
                flatpak install -y flathub "$app" \
                    || warn "Failed to install flatpak: $app"
            done < "$pkg_dir/flatpak.txt"
            success "Flatpak packages restored"
        else
            warn "flatpak not found; skipping $pkg_dir/flatpak.txt"
        fi
    fi

    # npm
    if [[ -s "$pkg_dir/npm.txt" ]]; then
        if command_exists npm; then
            info "Installing global npm packages..."
            if xargs -r npm install -g < "$pkg_dir/npm.txt"; then
                success "npm packages restored"
            else
                warn "Some npm packages failed to install"
            fi
        else
            warn "npm not found; skipping $pkg_dir/npm.txt"
        fi
    fi

    # pip / pip3
    if [[ -s "$pkg_dir/pip.txt" ]]; then
        local pip_cmd=""
        if command_exists pip3; then
            pip_cmd="pip3"
        elif command_exists pip; then
            pip_cmd="pip"
        fi

        if [[ -n "$pip_cmd" ]]; then
            info "Installing pip packages (via $pip_cmd)..."
            if "$pip_cmd" install -r "$pkg_dir/pip.txt"; then
                success "pip packages restored"
            else
                warn "Some pip packages failed to install"
            fi
        else
            warn "pip/pip3 not found; skipping $pkg_dir/pip.txt"
        fi
    fi

    # pipx
    if [[ -s "$pkg_dir/pipx.txt" ]]; then
        if command_exists pipx; then
            info "Installing pipx packages..."
            while IFS= read -r pkg; do
                [[ -n "$pkg" ]] || continue
                pipx install "$pkg" || warn "Failed to install pipx package: $pkg"
            done < "$pkg_dir/pipx.txt"
            success "pipx packages restored"
        else
            warn "pipx not found; skipping $pkg_dir/pipx.txt"
        fi
    fi

    # Cargo
    if [[ -s "$pkg_dir/cargo.txt" ]]; then
        if command_exists cargo; then
            info "Installing cargo packages..."
            while IFS= read -r pkg; do
                [[ -n "$pkg" ]] || continue
                cargo install "$pkg" || warn "Failed to install cargo package: $pkg"
            done < "$pkg_dir/cargo.txt"
            success "Cargo packages restored"
        else
            warn "cargo not found; skipping $pkg_dir/cargo.txt"
        fi
    fi

    success "Package restoration completed."
}
