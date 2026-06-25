#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/modules/wallpapers.sh"

TEST="$HOME/ArchForge-Wallpaper-Test"

rm -rf "$TEST"

mkdir -p "$TEST"

init_logger "$TEST"

backup_wallpapers "$TEST"

echo
echo "========== Wallpaper Backup =========="
find "$TEST"
