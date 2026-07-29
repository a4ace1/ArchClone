#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/version.sh"
source "$PROJECT_ROOT/lib/logging.sh"
source "$PROJECT_ROOT/lib/utils.sh"
source "$PROJECT_ROOT/lib/discovery.sh"
source "$PROJECT_ROOT/lib/rsync_wrapper.sh"
source "$PROJECT_ROOT/lib/manifest.sh"
source "$PROJECT_ROOT/lib/restore_loader.sh"
source "$PROJECT_ROOT/lib/archive.sh"
source "$PROJECT_ROOT/lib/checksums.sh"
