#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/logging.sh"
source "$PROJECT_ROOT/lib/checksums.sh"

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/archforge-checksum-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

TEST="$SANDBOX/ArchForge-Test"
mkdir -p "$TEST/sub"
echo "hello" > "$TEST/sample.txt"
echo "world" > "$TEST/sub/nested.txt"

init_logger "$TEST"

generate_checksums "$TEST"

[[ -s "$TEST/checksums.sha256" ]] || { echo "FAIL: checksums.sha256 was not generated"; exit 1; }

echo
echo "========== Checksums ==========" 
cat "$TEST/checksums.sha256"

echo
echo "========== Verifying (should pass) =========="
verify_checksums "$TEST"

echo
echo "========== Tampering with a file and re-verifying (should fail) =========="
echo "tampered" >> "$TEST/sample.txt"
if verify_checksums "$TEST" 2>/tmp/archforge-checksum-test-tamper.log; then
    echo "FAIL: verify_checksums did not detect tampering"
    exit 1
fi
echo "OK: verify_checksums correctly detected tampering"
rm -f /tmp/archforge-checksum-test-tamper.log

echo
echo "PASS"
