#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_ROOT/lib/version.sh"

ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
    esac
done

# install_prompt <question>
#
# Wraps `read -rp` so install.sh never hangs in non-interactive
# contexts (CI, `curl | bash`, etc): if stdin isn't a terminal and
# --yes/-y wasn't passed, default to "no" instead of blocking.
install_prompt() {
    local question="$1"
    local reply

    if [[ "$ASSUME_YES" == "1" ]]; then
        echo "$question [y/N]: y (--yes)"
        return 0
    fi

    if [[ ! -t 0 ]]; then
        echo "$question [y/N]: n (non-interactive, skipping)"
        return 1
    fi

    read -rp "$question [y/N]: " reply
    case "$reply" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

echo "Installing ArchForge v${ARCHFORGE_VERSION}..."
echo

# --- 1. Set executable permissions ----------------------------------
echo "Setting executable permissions..."
chmod +x \
    "$PROJECT_ROOT/archforge" \
    "$PROJECT_ROOT/backup.sh" \
    "$PROJECT_ROOT/restore.sh" \
    "$PROJECT_ROOT/verify.sh" \
    "$PROJECT_ROOT/doctor.sh" \
    "$PROJECT_ROOT/install.sh"
echo "  done."
echo

# --- 2. Verify environment / dependencies ---------------------------
echo "Checking environment..."
"$PROJECT_ROOT/doctor.sh" || {
    echo
    echo "Warning: doctor.sh reported issues. ArchForge may not work" >&2
    echo "correctly until they are resolved (see above)." >&2
}
echo

# --- 3. Optionally install missing dependencies (Arch Linux only) ---
if command -v pacman >/dev/null 2>&1; then
    MISSING=()
    for dep in tar zstd rsync; do
        command -v "$dep" >/dev/null 2>&1 || MISSING+=("$dep")
    done

    if [[ ${#MISSING[@]} -gt 0 ]]; then
        echo "Missing dependencies detected: ${MISSING[*]}"
        if install_prompt "Install them now with pacman?"; then
            sudo pacman -S --needed "${MISSING[@]}"
        else
            echo "Skipping automatic dependency installation."
            echo "Install manually with: sudo pacman -S --needed ${MISSING[*]}"
        fi
    else
        echo "All required dependencies are already installed."
    fi
else
    echo "pacman not found (non-Arch system); skipping automatic dependency installation."
    echo "Ensure the following are installed manually: tar, zstd, rsync, coreutils (sha256sum)."
fi
echo

# --- 4. Offer to install a launcher on PATH --------------------------
DEFAULT_BIN_DIR="$HOME/.local/bin"
if install_prompt "Install the 'archforge' launcher to $DEFAULT_BIN_DIR?"; then
    mkdir -p "$DEFAULT_BIN_DIR"
    ln -sf "$PROJECT_ROOT/archforge" "$DEFAULT_BIN_DIR/archforge"
    echo "Linked $DEFAULT_BIN_DIR/archforge -> $PROJECT_ROOT/archforge"
    case ":$PATH:" in
        *":$DEFAULT_BIN_DIR:"*) ;;
        *)
            echo "Note: $DEFAULT_BIN_DIR is not on your \$PATH."
            echo "Add this to your shell profile:"
            echo "  export PATH=\"\$PATH:$DEFAULT_BIN_DIR\""
            ;;
    esac
else
    echo "Skipping launcher installation. Run ArchForge directly via:"
    echo "  $PROJECT_ROOT/archforge"
fi
echo

echo "ArchForge installation complete."
echo "Try: ./archforge doctor"
