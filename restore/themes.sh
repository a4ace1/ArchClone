#!/usr/bin/env bash

# ==========================================================
# ArchClone Themes Restore
# ==========================================================

set -Eeuo pipefail

restore_themes() {

    local backup_root="$1"

    info "Restoring GTK themes..."

    for rel in ".themes" ".local/share/themes"; do
        if [[ -e "$backup_root/home/$rel" ]]; then
            rsync_restore_path "$rel" "$backup_root"
            success "Restored: $rel"
        fi
    done
}
