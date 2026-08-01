#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/lib/banner.sh"
show_banner

source "$PROJECT_ROOT/lib/version.sh"
source "$PROJECT_ROOT/lib/utils.sh"

ISSUES=0

check_pass() { printf "  [OK]   %s\n" "$1"; }
check_warn() { printf "  [WARN] %s\n" "$1"; }
check_fail() { printf "  [FAIL] %s\n" "$1"; ISSUES=$((ISSUES + 1)); }

echo "ArchClone Doctor — v${ARCHCLONE_VERSION}"
echo

echo "== Required dependencies =="
for cmd in tar sha256sum; do
    if command_exists "$cmd"; then
        check_pass "$cmd found ($(command -v "$cmd"))"
    else
        check_fail "$cmd not found — required for backup/verify"
    fi
done

if command_exists zstd || tar --help 2>&1 | grep -q -- '--zstd'; then
    check_pass "zstd support available"
else
    check_fail "zstd not found — required for compressing/extracting .tar.zst archives"
fi

if command_exists rsync; then
    check_pass "rsync found ($(command -v rsync))"
else
    check_fail "rsync not found — required for all backup/restore modules"
fi

if tar --help 2>&1 | grep -q -- '--xattrs' && tar --help 2>&1 | grep -q -- '--acls'; then
    check_pass "tar supports --xattrs/--acls"
else
    check_fail "tar does not support --xattrs/--acls — backups will silently drop extended attributes and ACLs"
fi

if command_exists setfattr && command_exists getfattr; then
    check_pass "setfattr/getfattr found (attr package)"
else
    check_warn "attr package not found — extended attributes may not be readable/settable outside of tar itself"
fi

if command_exists setfacl && command_exists getfacl; then
    check_pass "setfacl/getfacl found (acl package)"
else
    check_warn "acl package not found — ACLs may not be readable/settable outside of tar itself"
fi

echo
echo "== Optional dependencies =="
for cmd in shellcheck pacman yay flatpak npm pip pip3 pipx cargo hostnamectl lspci findmnt pgrep; do
    if command_exists "$cmd"; then
        check_pass "$cmd found"
    else
        check_warn "$cmd not found (optional; related features will be skipped)"
    fi
done

echo
echo "== Disk space =="
if command_exists df; then
    AVAIL_KB="$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')" || true
    if [[ -n "${AVAIL_KB:-}" ]]; then
        AVAIL_HUMAN="$(human_size $((AVAIL_KB * 1024)) 2>/dev/null || echo "${AVAIL_KB}KB")"
        if [[ "$AVAIL_KB" -lt 1048576 ]]; then # < 1GB
            check_warn "Only $AVAIL_HUMAN free under \$HOME — backups may not fit"
        else
            check_pass "$AVAIL_HUMAN free under \$HOME"
        fi
    else
        check_warn "Could not determine free disk space"
    fi
else
    check_warn "df not found — cannot check disk space"
fi

echo
echo "== Permissions =="
if [[ -w "$HOME" ]]; then
    check_pass "\$HOME ($HOME) is writable"
else
    check_fail "\$HOME ($HOME) is not writable"
fi

if [[ -r "$PROJECT_ROOT/config/exclude.conf" ]]; then
    check_pass "config/exclude.conf is readable"
else
    check_warn "config/exclude.conf not found or unreadable — backups will not apply exclusions"
fi

echo
echo "== Environment =="
if [[ -n "${HOME:-}" ]]; then
    check_pass "\$HOME is set ($HOME)"
else
    check_fail "\$HOME is not set"
fi

if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    check_pass "Bash version ${BASH_VERSION} (>= 4.0)"
else
    check_fail "Bash version ${BASH_VERSION} is too old (need >= 4.0)"
fi

echo
if [[ "$ISSUES" -eq 0 ]]; then
    echo "All critical checks passed."
    exit 0
else
    echo "$ISSUES critical issue(s) found."
    exit 1
fi
