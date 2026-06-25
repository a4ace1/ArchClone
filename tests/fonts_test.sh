#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/modules/fonts.sh"

TEST_DIR="$HOME/ArchForge-Fonts-Test"

rm -rf "$TEST_DIR"

mkdir -p "$TEST_DIR"

init_logger "$TEST_DIR"

backup_fonts "$TEST_DIR"

echo
echo "========== Fonts Backup =========="
find "$TEST_DIR"
