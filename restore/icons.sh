#!/usr/bin/env bash

# ==========================================================
# ArchForge Icons Restore
# ==========================================================

set -Eeuo pipefail

restore_icons() {

    local backup_root="$1"

    info "Restoring icon themes..."

    for rel in ".icons" ".local/share/icons"; do
        if [[ -e "$backup_root/home/$rel" ]]; then
            rsync_restore_path "$rel" "$backup_root"
            success "Restored: $rel"
        fi
    done
}
