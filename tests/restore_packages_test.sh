#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/restore/packages.sh"

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/archclone-restore-packages-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

TEST="$SANDBOX/backup"

init_logger "$TEST"

echo "--- Case 1: no packages/ directory at all (should no-op cleanly) ---"
mkdir -p "$TEST"
restore_packages "$TEST"

echo
echo "--- Case 2: packages/ present but ARCHCLONE_SKIP_PACKAGES=1 (should skip) ---"
mkdir -p "$TEST/packages"
echo "some-package" > "$TEST/packages/pacman.txt"
ARCHCLONE_SKIP_PACKAGES=1 restore_packages "$TEST"

echo
echo "--- Case 3: packages/ present, no package managers on PATH (should warn + no-op per manager) ---"
# In this sandboxed test environment there is no pacman/yay/etc, so this
# exercises the "package manager not found, skip" path for every manager
# without actually installing anything.
restore_packages "$TEST"

echo
echo "PASS"
