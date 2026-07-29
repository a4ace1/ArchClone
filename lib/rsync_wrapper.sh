#!/usr/bin/env bash

# ==========================================================
# ArchForge rsync Wrapper
#
# Single shared implementation of "copy this path into the backup"
# and "copy this path back out of the backup" used by every backup
# and restore module. Centralising this:
#
#   - guarantees every module preserves the same rsync flags
#     (archive mode, symlinks, timestamps, permissions, ACLs, xattrs)
#   - guarantees every module honours config/exclude.conf
#   - preserves each source's *original location relative to $HOME*
#     so distinct sources never flatten/collide into one destination
#     (e.g. ~/.fonts and ~/.local/share/fonts each keep their own
#     path instead of both landing in "fonts/")
#   - makes restores portable: nothing in the backup encodes an
#     absolute, machine-specific home directory, so a backup made on
#     /home/alice restores correctly under /home/bob
# ==========================================================

set -Eeuo pipefail

_archforge_rsync_wrapper_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_archforge_rsync_wrapper_dir/logging.sh"
source "$_archforge_rsync_wrapper_dir/utils.sh"

: "${ARCHFORGE_EXCLUDE_FILE:=$_archforge_rsync_wrapper_dir/../config/exclude.conf}"

unset _archforge_rsync_wrapper_dir

# _archforge_relative_to_home <absolute_path>
#
# Prints <absolute_path> relative to $HOME. Paths outside $HOME are
# preserved (minus their leading slash) under a "root/" namespace so
# they can never collide with a $HOME-relative path.
_archforge_relative_to_home() {
    local path="$1"
    local home="${HOME%/}"

    case "$path" in
        "$home"/*)
            printf "%s\n" "${path#"$home"/}"
            ;;
        "$home")
            printf "%s\n" "."
            ;;
        *)
            printf "root/%s\n" "${path#/}"
            ;;
    esac
}

# rsync_backup_path <source_path> <backup_root>
#
# Backs up <source_path> (file or directory) into
# <backup_root>/home/<path-relative-to-$HOME>, applying the shared
# exclude list. No-op (returns 0) if the source doesn't exist.
rsync_backup_path() {
    local src="$1"
    local backup_root="$2"

    [[ -e "$src" ]] || return 0

    require_command rsync

    local rel dest
    rel="$(_archforge_relative_to_home "$src")"
    dest="$backup_root/home/$rel"

    ensure_directory "$(dirname "$dest")"

    local rsync_args=(-aHAX)
    if [[ -f "$ARCHFORGE_EXCLUDE_FILE" ]]; then
        rsync_args+=(--exclude-from="$ARCHFORGE_EXCLUDE_FILE")
    fi

    if [[ -d "$src" ]]; then
        ensure_directory "$dest"
        rsync "${rsync_args[@]}" "$src/" "$dest/"
    else
        rsync "${rsync_args[@]}" "$src" "$dest"
    fi
}

# rsync_restore_path <relative_path> <backup_root> [<target_home>]
#
# Restores <backup_root>/home/<relative_path> back to
# <target_home>/<relative_path> (defaults to $HOME). Because the
# backup only ever stores paths relative to $HOME, this works
# regardless of which machine/user the backup was originally taken
# on. No-op (returns 0) if the path isn't present in the backup.
rsync_restore_path() {
    local rel="$1"
    local backup_root="$2"
    local target_home="${3:-${ARCHFORGE_TARGET_HOME:-$HOME}}"

    local src="$backup_root/home/$rel"
    [[ -e "$src" ]] || return 0

    require_command rsync

    local dest="$target_home/$rel"
    ensure_directory "$(dirname "$dest")"

    local rsync_args=(-aHAX)

    if [[ -d "$src" ]]; then
        ensure_directory "$dest"
        rsync "${rsync_args[@]}" "$src/" "$dest/"
    else
        rsync "${rsync_args[@]}" "$src" "$dest"
    fi
}

# rsync_restore_all_under <relative_prefix> <backup_root> [<target_home>]
#
# Restores every path backed up under home/<relative_prefix>/* back
# into <target_home>/<relative_prefix>/*. Useful for modules (fonts,
# icons, themes) that back up several candidate directories and want
# to restore whichever of them actually exist in the backup.
rsync_restore_all_under() {
    local rel_prefix="$1"
    local backup_root="$2"
    local target_home="${3:-$HOME}"

    local src="$backup_root/home/$rel_prefix"
    [[ -d "$src" ]] || return 0

    rsync_restore_path "$rel_prefix" "$backup_root" "$target_home"
}
