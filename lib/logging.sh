#!/usr/bin/env bash

# ==========================================================
# ArchForge Logging Library
# ==========================================================

set -Eeuo pipefail

: "${LOG_FILE:=}"

init_logger() {
    local log_dir="$1"

    mkdir -p "$log_dir"

    LOG_FILE="$log_dir/archforge.log"

    touch "$LOG_FILE"
}

_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

_log() {
    local level="$1"
    local color="$2"
    local message="$3"

    printf "%b[%s] [%s]%b %s\n" \
        "$color" \
        "$(_timestamp)" \
        "$level" \
        "\033[0m" \
        "$message"

echo "========== DEBUG ==========" >&2
echo "LOG_FILE='$LOG_FILE'" >&2
echo "PWD='$(pwd)'" >&2
echo "===========================" >&2

    printf "[%s] [%s] %s\n" \
        "$(_timestamp)" \
        "$level" \
        "$message" >> "$LOG_FILE"
}

info() {
    _log "INFO" "\033[0;36m" "$1"
}

success() {
    _log "SUCCESS" "\033[0;32m" "$1"
}

warn() {
    _log "WARNING" "\033[1;33m" "$1"
}

error() {
    _log "ERROR" "\033[0;31m" "$1"
}

debug() {
    _log "DEBUG" "\033[0;35m" "$1"
}

die() {
    error "$1"
    exit 1
}
