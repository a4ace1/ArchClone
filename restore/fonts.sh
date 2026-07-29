#!/usr/bin/env bash

# ==========================================================
# ArchForge Fonts Restore
# ==========================================================

set -Eeuo pipefail

restore_fonts() {

    local backup_root="$1"

    info "Restoring fonts..."

    local restored=0
    for rel in ".local/share/fonts" ".fonts"; do
        if [[ -e "$backup_root/home/$rel" ]]; then
            rsync_restore_path "$rel" "$backup_root"
            success "Restored: $rel"
            restored=1
        fi
    done

    if [[ "$restored" -eq 1 ]] && command_exists fc-cache; then
        info "Refreshing font cache..."
        fc-cache -f >/dev/null 2>&1 || warn "fc-cache failed to refresh the font cache"
    fi
}
