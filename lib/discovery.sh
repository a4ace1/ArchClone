#!/usr/bin/env bash

# ==========================================================
# ArchClone Discovery Library
#
# NOTE on exit statuses: every public discover_* function is safe to
# call as a bare statement under `set -e` (as the tests and manifest
# generation do). None of them may end on a command whose exit status
# reflects "not found" (e.g. a bare `[[ -f x ]] && echo x`), because
# that pattern makes the *function's own* return status equal to the
# test's failure, which would abort the calling script under -e.
# Every function below therefore finishes with an explicit `return 0`
# (or is structured so its final statement always succeeds).
# ==========================================================

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

discover_hostname() {
    hostnamectl --static 2>/dev/null || hostname
    return 0
}

discover_kernel() {
    uname -r
    return 0
}

discover_architecture() {
    uname -m
    return 0
}

discover_shell() {
    basename "${SHELL:-unknown}"
    return 0
}

discover_user() {
    id -un
    return 0
}

discover_home() {
    printf "%s\n" "$HOME"
    return 0
}

discover_terminal() {
    printf "%s\n" "${TERM:-unknown}"
    return 0
}

discover_cpu() {
    if [[ -r /proc/cpuinfo ]]; then
        awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo
    else
        echo "Unknown"
    fi
    return 0
}

discover_memory() {
    if [[ -r /proc/meminfo ]]; then
        awk '/MemTotal/ {
            printf "%.1f GB\n", $2 / 1024 / 1024
        }' /proc/meminfo
    else
        echo "Unknown"
    fi
    return 0
}

discover_gpu() {
    if command_exists lspci; then
        lspci | awk '/VGA compatible controller|3D controller|Display controller/'
    else
        echo "Unknown"
    fi
    return 0
}

discover_hostnamectl() {
    hostnamectl 2>/dev/null || true
    return 0
}

discover_filesystem() {
    if command_exists findmnt; then
        findmnt -n -o FSTYPE / 2>/dev/null || echo "Unknown"
    else
        echo "Unknown"
    fi
    return 0
}

discover_uptime() {
    if command_exists uptime; then
        uptime -p 2>/dev/null || echo "Unknown"
    else
        echo "Unknown"
    fi
    return 0
}

discover_desktop() {
    printf "%s\n" "${XDG_CURRENT_DESKTOP:-Unknown}"
    return 0
}

discover_session() {
    printf "%s\n" "${XDG_SESSION_TYPE:-Unknown}"
    return 0
}

discover_window_manager() {
    if command_exists pgrep && pgrep -x Hyprland >/dev/null 2>&1; then
        echo "Hyprland"
    elif command_exists pgrep && pgrep -x sway >/dev/null 2>&1; then
        echo "Sway"
    elif command_exists pgrep && pgrep -x i3 >/dev/null 2>&1; then
        echo "i3"
    else
        echo "Unknown"
    fi
    return 0
}

discover_package_managers() {
    local managers=()

    for pm in pacman paru yay flatpak snap cargo npm pip pip3 pipx go; do
        if command_exists "$pm"; then
            managers+=("$pm")
        fi
    done

    if [[ ${#managers[@]} -gt 0 ]]; then
        printf "%s\n" "${managers[@]}"
    fi
    return 0
}

discover_shells() {
    if [[ -r /etc/passwd ]]; then
        awk -F: '$7 ~ /(bash|zsh|fish|sh)$/ {print $7}' /etc/passwd | sort -u
    fi
    return 0
}

discover_editors() {
    local editors=()

    for editor in nvim vim nano code cursor helix emacs; do
        if command_exists "$editor"; then
            editors+=("$editor")
        fi
    done

    if [[ ${#editors[@]} -gt 0 ]]; then
        printf "%s\n" "${editors[@]}"
    fi
    return 0
}

discover_terminals() {
    local terminals=()

    for term in alacritty kitty foot wezterm gnome-terminal xfce4-terminal konsole; do
        if command_exists "$term"; then
            terminals+=("$term")
        fi
    done

    if [[ ${#terminals[@]} -gt 0 ]]; then
        printf "%s\n" "${terminals[@]}"
    fi
    return 0
}

discover_browsers() {
    local browsers=()

    for browser in firefox thorium-browser thorium chromium google-chrome brave zen floorp librewolf vivaldi; do
        if command_exists "$browser"; then
            browsers+=("$browser")
        fi
    done

    if [[ ${#browsers[@]} -gt 0 ]]; then
        printf "%s\n" "${browsers[@]}"
    fi
    return 0
}

# ==========================================================
# Hyprland / Rice Discovery
# ==========================================================

discover_hyprland_config() {
    local cfg="$HOME/.config/hypr/hyprland.conf"

    if [[ -f "$cfg" ]]; then
        printf "%s\n" "$cfg"
    fi
    return 0
}

discover_hypr_configs() {
    local dir="$HOME/.config/hypr"

    [[ -d "$dir" ]] || return 0

    find "$dir" -type f -name "*.conf" | sort
    return 0
}

discover_waybar_config() {
    local dir="$HOME/.config/waybar"

    if [[ -d "$dir" ]]; then
        printf "%s\n" "$dir"
    fi
    return 0
}

discover_rofi_config() {
    local dir="$HOME/.config/rofi"

    if [[ -d "$dir" ]]; then
        printf "%s\n" "$dir"
    fi
    return 0
}

discover_alacritty_config() {
    local cfg="$HOME/.config/alacritty/alacritty.toml"

    if [[ -f "$cfg" ]]; then
        printf "%s\n" "$cfg"
    fi
    return 0
}

discover_kitty_config() {
    local cfg="$HOME/.config/kitty/kitty.conf"

    if [[ -f "$cfg" ]]; then
        printf "%s\n" "$cfg"
    fi
    return 0
}

discover_wallpaper_manager() {
    for mgr in hyprpaper swww waypaper feh nitrogen; do
        if command_exists "$mgr"; then
            echo "$mgr"
            return 0
        fi
    done

    echo "unknown"
    return 0
}

discover_fonts() {
    local dirs=(
        "$HOME/.local/share/fonts"
        "$HOME/.fonts"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "$dir"
        fi
    done
    return 0
}

discover_themes() {
    local dirs=(
        "$HOME/.themes"
        "$HOME/.local/share/themes"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "$dir"
        fi
    done
    return 0
}

discover_icons() {
    local dirs=(
        "$HOME/.icons"
        "$HOME/.local/share/icons"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "$dir"
        fi
    done
    return 0
}

discover_wallpapers() {
    local candidates=(
        "$HOME/Wallpapers"
        "$HOME/.wallpapers"
        "$HOME/.config/hypr/wallpapers"
    )

    for dir in "${candidates[@]}"; do
        if [[ -d "$dir" ]]; then
            printf "%s\n" "$dir"
        fi
    done

    # Prefer the more specific Pictures/Wallpapers if it exists; only
    # fall back to the whole Pictures directory (which would otherwise
    # redundantly re-back-up the same files twice) when it doesn't.
    if [[ -d "$HOME/Pictures/Wallpapers" ]]; then
        printf "%s\n" "$HOME/Pictures/Wallpapers"
    elif [[ -d "$HOME/Pictures" ]]; then
        printf "%s\n" "$HOME/Pictures"
    fi

    if [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
        grep -Eo '/[^", ]+\.(png|jpg|jpeg|webp|gif)' \
            "$HOME/.config/hypr/hyprland.conf" 2>/dev/null | \
            xargs -r -n1 dirname | \
            sort -u || true
    fi
    return 0
}
