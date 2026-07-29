#!/usr/bin/env bash

# ==========================================================
# ArchClone End-to-End Round-Trip Test
#
# Simulates a full backup -> verify -> compress -> restore cycle
# against a throwaway fake $HOME, covering:
#   1. backup.sh producing a directory backup + compressed archive
#   2. verify.sh validating both the directory and the archive
#   3. restore.sh restoring from the *extracted directory*
#   4. restore.sh restoring from the *compressed archive* (portable:
#      into a different fake "user"'s $HOME, proving issue 9/10 are
#      actually fixed)
#   5. Byte-for-byte comparison of restored files against originals
#
# Exits non-zero (and prints which check failed) on any mismatch.
# ==========================================================

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PASS=0
FAIL=0

check() {
    local description="$1"
    shift
    if "$@"; then
        echo "  [PASS] $description"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $description"
        FAIL=$((FAIL + 1))
    fi
}

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/archclone-e2e.XXXXXX")"
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

echo "Sandbox: $SANDBOX"

# --- 1. Build a fake $HOME (as user "alice") with representative data ---
ALICE_HOME="$SANDBOX/home-alice"
mkdir -p \
    "$ALICE_HOME/.config/hypr" \
    "$ALICE_HOME/.config/waybar" \
    "$ALICE_HOME/.fonts" \
    "$ALICE_HOME/.local/share/fonts" \
    "$ALICE_HOME/.themes/MyTheme" \
    "$ALICE_HOME/.icons/MyIcons" \
    "$ALICE_HOME/Pictures/Wallpapers"

echo 'monitor=,preferred,auto,1' > "$ALICE_HOME/.config/hypr/hyprland.conf"
echo '{"layer":"top"}' > "$ALICE_HOME/.config/waybar/config"
echo 'export EDITOR=nvim' > "$ALICE_HOME/.bashrc"
echo "font-from-dot-fonts" > "$ALICE_HOME/.fonts/a.ttf"
echo "font-from-local-share" > "$ALICE_HOME/.local/share/fonts/b.ttf"
echo "theme-data" > "$ALICE_HOME/.themes/MyTheme/index.theme"
echo "icon-data" > "$ALICE_HOME/.icons/MyIcons/index.theme"
echo "wallpaper-bytes" > "$ALICE_HOME/Pictures/Wallpapers/sunset.png"

echo
echo "== Step 1: backup.sh (as HOME=$ALICE_HOME) =="
BACKUP_DIR="$SANDBOX/archclone-backup"
HOME="$ALICE_HOME" "$PROJECT_ROOT/backup.sh" "$BACKUP_DIR"

check "manifest.json created" test -f "$BACKUP_DIR/manifest.json"
check "checksums.sha256 created" test -f "$BACKUP_DIR/checksums.sha256"
check "compressed archive created" bash -c 'ls '"$SANDBOX"'/archclone-backup-*.tar.zst >/dev/null 2>&1'
ARCHIVE="$(find "$SANDBOX" -maxdepth 1 -name "archclone-backup-*.tar.zst" -print -quit)"

check "user .fonts dir preserved distinctly" test -f "$BACKUP_DIR/home/.fonts/a.ttf"
check "user local/share/fonts dir preserved distinctly" test -f "$BACKUP_DIR/home/.local/share/fonts/b.ttf"
check "hyprland.conf backed up" test -f "$BACKUP_DIR/home/.config/hypr/hyprland.conf"
check ".bashrc backed up" test -f "$BACKUP_DIR/home/.bashrc"

echo
echo "== Step 2: verify.sh against the directory =="
check "verify.sh passes on directory" "$PROJECT_ROOT/verify.sh" "$BACKUP_DIR"

echo
echo "== Step 3: verify.sh against the compressed archive =="
check "verify.sh passes on archive" "$PROJECT_ROOT/verify.sh" "$ARCHIVE"

echo
echo "== Step 4: restore.sh from the extracted directory (into HOME=bob) =="
BOB_HOME="$SANDBOX/home-bob"
mkdir -p "$BOB_HOME"
HOME="$BOB_HOME" ARCHCLONE_SKIP_PACKAGES=1 "$PROJECT_ROOT/restore.sh" "$BACKUP_DIR" --yes --home "$BOB_HOME"

check "bob: .bashrc restored" test -f "$BOB_HOME/.bashrc"
check "bob: .fonts/a.ttf restored" test -f "$BOB_HOME/.fonts/a.ttf"
check "bob: local/share/fonts/b.ttf restored" test -f "$BOB_HOME/.local/share/fonts/b.ttf"
check "bob: .bashrc content matches original" \
    bash -c "diff -q '$ALICE_HOME/.bashrc' '$BOB_HOME/.bashrc' >/dev/null"
check "bob: hyprland.conf content matches original" \
    bash -c "diff -q '$ALICE_HOME/.config/hypr/hyprland.conf' '$BOB_HOME/.config/hypr/hyprland.conf' >/dev/null"
check "bob: wallpaper content matches original" \
    bash -c "diff -q '$ALICE_HOME/Pictures/Wallpapers/sunset.png' '$BOB_HOME/Pictures/Wallpapers/sunset.png' >/dev/null"

echo
echo "== Step 5: restore.sh directly from the .tar.zst archive (into HOME=carol) =="
CAROL_HOME="$SANDBOX/home-carol"
mkdir -p "$CAROL_HOME"
HOME="$CAROL_HOME" ARCHCLONE_SKIP_PACKAGES=1 "$PROJECT_ROOT/restore.sh" "$ARCHIVE" --yes --home "$CAROL_HOME"

check "carol: .bashrc restored from archive" test -f "$CAROL_HOME/.bashrc"
check "carol: theme restored from archive" test -f "$CAROL_HOME/.themes/MyTheme/index.theme"
check "carol: icon theme restored from archive" test -f "$CAROL_HOME/.icons/MyIcons/index.theme"
check "carol: .bashrc content matches original" \
    bash -c "diff -q '$ALICE_HOME/.bashrc' '$CAROL_HOME/.bashrc' >/dev/null"
check "carol: waybar config content matches original" \
    bash -c "diff -q '$ALICE_HOME/.config/waybar/config' '$CAROL_HOME/.config/waybar/config' >/dev/null"

echo
echo "== Step 6: non-interactive restore without --yes must fail loudly, not hang =="
DAVE_HOME="$SANDBOX/home-dave"
mkdir -p "$DAVE_HOME"
if HOME="$DAVE_HOME" timeout 10 "$PROJECT_ROOT/restore.sh" "$BACKUP_DIR" --home "$DAVE_HOME" < /dev/null >/tmp/e2e-dave.log 2>&1; then
    echo "  [FAIL] restore.sh without --yes and no tty should have exited non-zero"
    FAIL=$((FAIL + 1))
else
    rc=$?
    if [[ "$rc" -eq 124 ]]; then
        echo "  [FAIL] restore.sh hung (timed out) instead of failing fast — this is exactly the stdin bug from issue #4"
        FAIL=$((FAIL + 1))
    else
        echo "  [PASS] restore.sh exited promptly ($rc) instead of hanging"
        PASS=$((PASS + 1))
    fi
fi

echo
echo "== Step 7: tampered backup must fail verification, not silently pass =="
TAMPER_DIR="$SANDBOX/tampered-backup"
cp -a "$BACKUP_DIR" "$TAMPER_DIR"
echo "corrupted" >> "$TAMPER_DIR/home/.bashrc"
if "$PROJECT_ROOT/verify.sh" "$TAMPER_DIR" >/tmp/e2e-tamper.log 2>&1; then
    echo "  [FAIL] verify.sh should have failed on a tampered backup"
    FAIL=$((FAIL + 1))
else
    echo "  [PASS] verify.sh correctly rejected the tampered backup"
    PASS=$((PASS + 1))
fi

echo
echo "=============================================="
echo "Results: $PASS passed, $FAIL failed"
echo "=============================================="

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
