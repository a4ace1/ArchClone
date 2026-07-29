#!/usr/bin/env bash

# ==========================================================
# ArchClone Version Library
#
# Single source of truth for the project version.
# Every script/module that needs the version number should
# source this file instead of hardcoding a version string.
# ==========================================================

# Guard against being sourced multiple times from different
# entry points (backup.sh, restore.sh, archclone, tests, ...).
if [[ -n "${ARCHCLONE_VERSION:-}" ]]; then
    # False positive: this is the standard "work whether sourced or
    # executed directly" guard. `return` exits this file's sourcing
    # when sourced; if this file is somehow executed directly instead
    # (not `return`-able), the `|| exit 0` branch is what actually
    # runs. ShellCheck's static analysis can't see that duality.
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
fi

_archclone_version_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHCLONE_PROJECT_ROOT="$(cd "$_archclone_version_lib_dir/.." && pwd)"
ARCHCLONE_VERSION_FILE="$ARCHCLONE_PROJECT_ROOT/VERSION"

if [[ -r "$ARCHCLONE_VERSION_FILE" ]]; then
    ARCHCLONE_VERSION="$(tr -d '[:space:]' < "$ARCHCLONE_VERSION_FILE")"
else
    # Should never happen in a correctly installed copy of ArchClone,
    # but fail soft rather than crashing every script that sources us.
    ARCHCLONE_VERSION="unknown"
fi

unset _archclone_version_lib_dir

readonly ARCHCLONE_VERSION
export ARCHCLONE_VERSION
