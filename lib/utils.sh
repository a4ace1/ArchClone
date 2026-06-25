#!/usr/bin/env bash

# ==========================================================
# ArchForge Utility Library
# Common helper functions
# ==========================================================

set -Eeuo pipefail

# Check whether a command exists.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Exit if a required command is missing.
require_command() {
    local cmd="$1"

    if ! command_exists "$cmd"; then
        echo "ERROR: Required command '$cmd' is not installed."
        exit 1
    fi
}

# Check if a file exists.
file_exists() {
    [[ -f "$1" ]]
}

# Check if a directory exists.
directory_exists() {
    [[ -d "$1" ]]
}

# Create a directory if it doesn't exist.
ensure_directory() {
    mkdir -p "$1"
}

# Return true if running as root.
is_root() {
    [[ "${EUID}" -eq 0 ]]
}

# Exit if not running as root.
require_root() {
    if ! is_root; then
        echo "ERROR: This operation requires root privileges."
        exit 1
    fi
}

# Convert bytes into human-readable format.
human_size() {
    numfmt --to=iec --suffix=B "$1"
}

# Prompt for yes/no confirmation.
confirm() {
    local prompt="$1"
    local reply

    while true; do
        read -rp "$prompt [y/N]: " reply

        case "$reply" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}
