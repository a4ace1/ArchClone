#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/logging.sh"
source "$PROJECT_ROOT/lib/checksums.sh"

TEST="$HOME/ArchForge-Test"

init_logger "$TEST"

generate_checksums "$TEST"

echo
echo "========== Checksums =========="
head "$TEST/checksums.sha256"
