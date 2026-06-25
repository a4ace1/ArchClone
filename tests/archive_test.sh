#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/logging.sh"
source "$PROJECT_ROOT/lib/archive.sh"

TEST="$HOME/ArchForge-Test"

init_logger "$TEST"

create_archive "$TEST" "$HOME/ArchForge-Test.tar.zst"
