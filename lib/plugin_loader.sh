#!/usr/bin/env bash

set -Eeuo pipefail

load_plugins() {

    local module

    for module in "$PROJECT_ROOT/modules/"*.sh; do
        source "$module"
    done
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
