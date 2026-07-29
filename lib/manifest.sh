#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/version.sh"

generate_manifest() {

    local backup_root="$1"

    cat > "$backup_root/manifest.json" <<EOF2
{
  "archclone_version": "${ARCHCLONE_VERSION}",
  "created": "$(date --iso-8601=seconds)",
  "hostname": "$(discover_hostname)",
  "user": "$(discover_user)",
  "home": "$(discover_home)",
  "kernel": "$(discover_kernel)",
  "architecture": "$(discover_architecture)",
  "desktop": "$(discover_desktop)",
  "session": "$(discover_session)",
  "window_manager": "$(discover_window_manager)"
}
EOF2

}
