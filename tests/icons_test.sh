#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/modules/icons.sh"

TEST="$HOME/ArchForge-Icons-Test"

rm -rf "$TEST"

mkdir -p "$TEST"

init_logger "$TEST"

backup_icons "$TEST"

echo
echo "========== Icon Backup =========="

find "$TEST"
