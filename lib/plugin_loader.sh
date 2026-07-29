#!/usr/bin/env bash

set -Eeuo pipefail

load_plugins() {

    local module

    # Modules are discovered dynamically by glob; the actual file list
    # can't be known statically.
    shopt -s nullglob
    for module in "$PROJECT_ROOT/modules/"*.sh; do
        # shellcheck disable=SC1090
        source "$module"
    done
    shopt -u nullglob
}

run_backup_plugins() {

    local backup_root="$1"
    local fn

    info "Running backup plugins..."

    while read -r _ _ fn; do

        [[ "$fn" == backup_* ]] || continue

        info "Executing: $fn"

        "$fn" "$backup_root"

    done < <(declare -F)

    success "All plugins completed."
}
