#!/usr/bin/env bash

set -Eeuo pipefail

load_restore_plugins() {

    local module

    for module in "$PROJECT_ROOT/restore/"*.sh; do
        [[ -f "$module" ]] || continue
        # Modules are discovered dynamically by glob; the actual file
        # list can't be known statically.
        # shellcheck disable=SC1090
        source "$module"
    done
}

run_restore_plugins() {

    local backup_root="$1"
    local fn

    info "Running restore plugins..."

    while read -r _ _ fn; do
        [[ "$fn" == restore_* ]] || continue

        info "Executing: $fn"

        "$fn" "$backup_root"
    done < <(declare -F)

    success "Restore plugins completed."
}
