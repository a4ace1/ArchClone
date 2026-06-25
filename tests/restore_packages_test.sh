#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/restore/packages.sh"

TEST="$HOME/ArchForge-Test"

init_logger "$TEST"

restore_packages "$TEST"
