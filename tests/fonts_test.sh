#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/modules/fonts.sh"

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/archclone-fonts-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

# Fake a $HOME with two distinct font source directories, which is
# exactly the scenario that used to collide/flatten (see CHANGELOG):
# ~/.fonts and ~/.local/share/fonts both landing in the same
# destination and clobbering each other.
export HOME="$SANDBOX/home"
mkdir -p "$HOME/.fonts" "$HOME/.local/share/fonts"
echo "font-a" > "$HOME/.fonts/a.ttf"
echo "font-b" > "$HOME/.local/share/fonts/b.ttf"

TEST_DIR="$SANDBOX/backup"
mkdir -p "$TEST_DIR"

init_logger "$TEST_DIR"

backup_fonts "$TEST_DIR"

echo
echo "========== Fonts Backup ==========" 
find "$TEST_DIR" -type f | sort

# Both sources must be preserved distinctly (no flattening/collision).
[[ -f "$TEST_DIR/home/.fonts/a.ttf" ]] \
    || { echo "FAIL: ~/.fonts/a.ttf missing from backup"; exit 1; }
[[ -f "$TEST_DIR/home/.local/share/fonts/b.ttf" ]] \
    || { echo "FAIL: ~/.local/share/fonts/b.ttf missing from backup"; exit 1; }
[[ "$(cat "$TEST_DIR/home/.fonts/a.ttf")" == "font-a" ]] \
    || { echo "FAIL: a.ttf content mismatch"; exit 1; }
[[ "$(cat "$TEST_DIR/home/.local/share/fonts/b.ttf")" == "font-b" ]] \
    || { echo "FAIL: b.ttf content mismatch"; exit 1; }

echo
echo "OK: both font source directories preserved without collision"
echo "PASS"
