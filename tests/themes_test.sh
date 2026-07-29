#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/modules/themes.sh"

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/archforge-themes-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

export HOME="$SANDBOX/home"
mkdir -p "$HOME/.themes/MyTheme" "$HOME/.local/share/themes/OtherTheme"
echo "theme-a" > "$HOME/.themes/MyTheme/index.theme"
echo "theme-b" > "$HOME/.local/share/themes/OtherTheme/index.theme"

TEST="$SANDBOX/backup"
mkdir -p "$TEST"

init_logger "$TEST"

backup_themes "$TEST"

echo
echo "========== Theme Backup ==========" 
find "$TEST" -type f | sort

[[ -f "$TEST/home/.themes/MyTheme/index.theme" ]] \
    || { echo "FAIL: ~/.themes/MyTheme missing from backup"; exit 1; }
[[ -f "$TEST/home/.local/share/themes/OtherTheme/index.theme" ]] \
    || { echo "FAIL: ~/.local/share/themes/OtherTheme missing from backup"; exit 1; }

echo
echo "OK: both theme source directories preserved without collision"
echo "PASS"
