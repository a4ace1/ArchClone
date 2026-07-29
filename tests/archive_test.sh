#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/logging.sh"
source "$PROJECT_ROOT/lib/utils.sh"
source "$PROJECT_ROOT/lib/archive.sh"

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/archforge-archive-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

TEST="$SANDBOX/ArchForge-Test"
ARCHIVE="$SANDBOX/ArchForge-Test.tar.zst"

mkdir -p "$TEST"
echo "hello" > "$TEST/sample.txt"
echo '{"archforge_version":"test"}' > "$TEST/manifest.json"

init_logger "$TEST"

create_archive "$TEST" "$ARCHIVE"

[[ -f "$ARCHIVE" ]] || { echo "FAIL: archive was not created"; exit 1; }

echo
echo "========== Archive created =========="
ls -lh "$ARCHIVE"

echo
echo "========== Round-trip: is_archive_file / extract_archive / find_backup_root =========="

is_archive_file "$ARCHIVE" || { echo "FAIL: is_archive_file did not recognize $ARCHIVE"; exit 1; }
echo "OK: is_archive_file recognizes the archive"

EXTRACT_DIR="$SANDBOX/extracted"
extract_archive "$ARCHIVE" "$EXTRACT_DIR"

FOUND_ROOT="$(find_backup_root "$EXTRACT_DIR")"
[[ -f "$FOUND_ROOT/sample.txt" ]] || { echo "FAIL: sample.txt missing after extraction"; exit 1; }
[[ "$(cat "$FOUND_ROOT/sample.txt")" == "hello" ]] || { echo "FAIL: sample.txt content mismatch"; exit 1; }

echo "OK: extract_archive + find_backup_root round-tripped sample.txt correctly"
echo
echo "PASS"
