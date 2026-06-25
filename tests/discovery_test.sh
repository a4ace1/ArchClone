#!/usr/bin/env bash

set -Eeuo pipefail

source lib/discovery.sh

echo "===== ArchForge Discovery Test ====="

echo "Hostname     : $(discover_hostname)"
echo "Kernel       : $(discover_kernel)"
echo "Architecture : $(discover_architecture)"
echo "Shell        : $(discover_shell)"
echo "User         : $(discover_user)"
echo "Home         : $(discover_home)"
echo "Terminal     : $(discover_terminal)"
echo "CPU          : $(discover_cpu)"
echo "Memory       : $(discover_memory)"
echo "GPU          : $(discover_gpu)"
echo "Filesystem  : $(discover_filesystem)"
echo "Desktop     : $(discover_desktop)"
echo "Session     : $(discover_session)"
echo "WM          : $(discover_window_manager)"
echo "Uptime      : $(discover_uptime)"
echo
echo "===== Software Discovery ====="

echo "Package Managers:"
discover_package_managers

echo
echo "Shells:"
discover_shells

echo
echo "Editors:"
discover_editors

echo
echo "Terminals:"
discover_terminals

echo
echo "Browsers:"
discover_browsers
echo
echo "===== Rice Discovery ====="

echo "Hyprland:"
discover_hyprland_config

echo
echo "Hypr Configs:"
discover_hypr_configs

echo
echo "Waybar:"
discover_waybar_config

echo
echo "Rofi:"
discover_rofi_config

echo
echo "Alacritty:"
discover_alacritty_config

echo
echo "Kitty:"
discover_kitty_config

echo
echo "Wallpapers:"
discover_wallpapers
