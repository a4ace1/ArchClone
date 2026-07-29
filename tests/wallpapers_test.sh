#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/modules/wallpapers.sh"

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/archclone-wallpapers-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

export HOME="$SANDBOX/home"
mkdir -p "$HOME/Pictures/Wallpapers"
echo "fake-png-data" > "$HOME/Pictures/Wallpapers/sunset.png"

TEST="$SANDBOX/backup"
mkdir -p "$TEST"

init_logger "$TEST"

backup_wallpapers "$TEST"

echo
echo "========== Wallpaper Backup ==========" 
find "$TEST" -type f | sort

[[ -f "$TEST/home/Pictures/Wallpapers/sunset.png" ]] \
    || { echo "FAIL: Pictures/Wallpapers/sunset.png missing from backup"; exit 1; }

echo
echo "OK: wallpaper directory preserved at its original relative path"
echo "PASS"
