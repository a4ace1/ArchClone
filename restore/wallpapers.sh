#!/usr/bin/env bash

# ==========================================================
# ArchForge Wallpapers Restore
# ==========================================================

set -Eeuo pipefail

restore_wallpapers() {

    local backup_root="$1"

    info "Restoring wallpapers..."

    local candidates=(
        "Wallpapers"
        "Pictures/Wallpapers"
        "Pictures"
        ".wallpapers"
        ".config/hypr/wallpapers"
    )

    local restored_wallpapers_subdir=0

    for rel in "${candidates[@]}"; do
        # Skip the general "Pictures" entry if we already restored the
        # more specific "Pictures/Wallpapers" — it's a subdirectory of
        # Pictures, so restoring both would just redundantly re-copy it.
        if [[ "$rel" == "Pictures" && "$restored_wallpapers_subdir" -eq 1 ]]; then
            continue
        fi

        if [[ -e "$backup_root/home/$rel" ]]; then
            rsync_restore_path "$rel" "$backup_root"
            success "Restored: $rel"
            [[ "$rel" == "Pictures/Wallpapers" ]] && restored_wallpapers_subdir=1
        fi
    done

    # NOTE: discover_wallpapers() also scans hyprland.conf at backup
    # time for any additional wallpaper directories referenced there,
    # and those get backed up under their own $HOME-relative path too.
    # We deliberately don't try to rediscover those paths here from
    # hyprland.conf, since after a restore hyprland.conf may not exist
    # yet (dotfiles restore may run in any order). Known limitation:
    # a wallpaper directory that (a) isn't one of the fixed candidates
    # above and (b) was only discovered via hyprland.conf parsing will
    # still be present under <backup>/home/<its-relative-path>/, but
    # won't be restored by this module automatically. Restore it
    # manually with:
    #   rsync -aHAX <backup>/home/<path>/ "$HOME/<path>/"
}
