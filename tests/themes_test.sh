#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/modules/themes.sh"

TEST="$HOME/ArchForge-Theme-Test"

rm -rf "$TEST"

mkdir -p "$TEST"

init_logger "$TEST"

backup_themes "$TEST"

echo
echo "========== Theme Backup =========="

find "$TEST"
