#!/usr/bin/env bash

# ==========================================================
# ArchClone Utility Library
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

# check_free_space <path> <required_bytes>
#
# Returns 0 if the filesystem containing <path> has at least
# <required_bytes> free, 1 otherwise. <path> need not exist yet --
# free space is checked on its nearest existing parent.
check_free_space() {
    local path="$1" required_bytes="$2"
    local check_path="$path"

    while [[ ! -e "$check_path" && "$check_path" != "/" ]]; do
        check_path="$(dirname "$check_path")"
    done

    local avail_kb
    avail_kb="$(df -Pk "$check_path" 2>/dev/null | awk 'NR==2 {print $4}')"
    [[ -n "$avail_kb" ]] || return 1

    local avail_bytes=$((avail_kb * 1024))
    (( avail_bytes >= required_bytes ))
}

# describe_path_filesystem <path>
#
# Prints "<filesystem-type> at <device>" for the filesystem backing
# <path>, or "unknown filesystem" if it can't be determined. Used to
# make error messages identify *which* filesystem/path a failure
# happened on, instead of just repeating the operation that failed.
describe_path_filesystem() {
    local path="$1"
    local check_path="$path"

    while [[ ! -e "$check_path" && "$check_path" != "/" ]]; do
        check_path="$(dirname "$check_path")"
    done

    local fstype source
    fstype="$(findmnt -no FSTYPE --target "$check_path" 2>/dev/null)"
    source="$(findmnt -no SOURCE --target "$check_path" 2>/dev/null)"

    if [[ -n "$fstype" ]]; then
        printf '%s at %s (mounted at %s)\n' "$fstype" "${source:-unknown device}" "$check_path"
    else
        printf 'unknown filesystem at %s\n' "$check_path"
    fi
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
