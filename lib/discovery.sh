#!/usr/bin/env bash

# ==========================================================
# ArchForge Discovery Library
# ==========================================================

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

discover_hostname() {
    hostnamectl --static 2>/dev/null || hostname
}

discover_kernel() {
    uname -r
}

discover_architecture() {
    uname -m
}

discover_shell() {
    basename "${SHELL:-unknown}"
}

discover_user() {
    id -un
}

discover_home() {
    printf "%s\n" "$HOME"
}

discover_terminal() {
    printf "%s\n" "${TERM:-unknown}"
}

discover_cpu() {
    awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo
}

discover_memory() {
    awk '/MemTotal/ {
        printf "%.1f GB\n", $2 / 1024 / 1024
    }' /proc/meminfo
}
discover_gpu() {
    if command_exists lspci; then
        lspci | awk '/VGA compatible controller|3D controller|Display controller/'
    else
        echo "Unknown"
    fi
}
discover_hostnamectl() {
    hostnamectl 2>/dev/null || true
}

discover_filesystem() {
    findmnt -n -o FSTYPE /
}

discover_uptime() {
    uptime -p
}

discover_desktop() {
    printf "%s\n" "${XDG_CURRENT_DESKTOP:-Unknown}"
}

discover_session() {
    printf "%s\n" "${XDG_SESSION_TYPE:-Unknown}"
}

discover_window_manager() {
    if pgrep -x Hyprland >/dev/null; then
        echo "Hyprland"
    elif pgrep -x sway >/dev/null; then
        echo "Sway"
    elif pgrep -x i3 >/dev/null; then
        echo "i3"
    else
        echo "Unknown"
    fi
}
discover_package_managers() {
    local managers=()

    for pm in pacman paru yay flatpak snap cargo npm pip pipx go; do
        if command_exists "$pm"; then
            managers+=("$pm")
        fi
    done

    printf "%s\n" "${managers[@]}"
}

discover_shells() {
    awk -F: '$7 ~ /(bash|zsh|fish|sh)$/ {print $7}' /etc/passwd | sort -u
}

discover_editors() {
    local editors=()

    for editor in nvim vim nano code cursor helix emacs; do
        if command_exists "$editor"; then
            editors+=("$editor")
        fi
    done

    printf "%s\n" "${editors[@]}"
}

discover_terminals() {
    local terminals=()

    for term in alacritty kitty foot wezterm gnome-terminal xfce4-terminal konsole; do
        if command_exists "$term"; then
            terminals+=("$term")
        fi
    done

    printf "%s\n" "${terminals[@]}"
}

discover_browsers() {
    local browsers=()

    for browser in firefox thorium-browser thorium chromium google-chrome brave zen floorp librewolf vivaldi; do
        if command_exists "$browser"; then
            browsers+=("$browser")
        fi
    done

    printf "%s\n" "${browsers[@]}"
}
# ==========================================================
# Hyprland Discovery
# ==========================================================

discover_hyprland_config() {
    local cfg="$HOME/.config/hypr/hyprland.conf"

    [[ -f "$cfg" ]] && printf "%s\n" "$cfg"
}

discover_hypr_configs() {
    local dir="$HOME/.config/hypr"

    [[ -d "$dir" ]] || return 0

    find "$dir" -type f -name "*.conf" | sort
}

discover_waybar_config() {
    local dir="$HOME/.config/waybar"

    [[ -d "$dir" ]] && printf "%s\n" "$dir"
}

discover_rofi_config() {
    local dir="$HOME/.config/rofi"

    [[ -d "$dir" ]] && printf "%s\n" "$dir"
}

discover_alacritty_config() {
    local cfg="$HOME/.config/alacritty/alacritty.toml"

    [[ -f "$cfg" ]] && printf "%s\n" "$cfg"
}

discover_kitty_config() {
    local cfg="$HOME/.config/kitty/kitty.conf"

    [[ -f "$cfg" ]] && printf "%s\n" "$cfg"
}
discover_wallpaper_manager() {

    if command_exists hyprpaper; then
        echo "hyprpaper"
        return
    fi

    if command_exists swww; then
        echo "swww"
        return
    fi

    if command_exists waypaper; then
        echo "waypaper"
        return
    fi

    if command_exists feh; then
        echo "feh"
        return
    fi

    if command_exists nitrogen; then
        echo "nitrogen"
        return
    fi

    echo "unknown"
}
