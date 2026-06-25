#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"

echo "========== Fonts =========="
discover_fonts

echo
echo "========== Themes =========="
discover_themes

echo
echo "========== Icons =========="
discover_icons

echo
echo "========== Wallpapers =========="
discover_wallpapers
