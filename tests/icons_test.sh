#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/modules/icons.sh"

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/archforge-icons-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

export HOME="$SANDBOX/home"
mkdir -p "$HOME/.icons/MyIconTheme" "$HOME/.local/share/icons/OtherIconTheme"
echo "icon-a" > "$HOME/.icons/MyIconTheme/index.theme"
echo "icon-b" > "$HOME/.local/share/icons/OtherIconTheme/index.theme"

TEST="$SANDBOX/backup"
mkdir -p "$TEST"

init_logger "$TEST"

backup_icons "$TEST"

echo
echo "========== Icon Backup ==========" 
find "$TEST" -type f | sort

[[ -f "$TEST/home/.icons/MyIconTheme/index.theme" ]] \
    || { echo "FAIL: ~/.icons/MyIconTheme missing from backup"; exit 1; }
[[ -f "$TEST/home/.local/share/icons/OtherIconTheme/index.theme" ]] \
    || { echo "FAIL: ~/.local/share/icons/OtherIconTheme missing from backup"; exit 1; }

echo
echo "OK: both icon source directories preserved without collision"
echo "PASS"
