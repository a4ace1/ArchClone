#!/usr/bin/env bash

set -Eeuo pipefail

generate_manifest() {

    local backup_root="$1"

    cat > "$backup_root/manifest.json" <<EOF
{
  "archforge_version": "0.1.0-alpha",
  "created": "$(date --iso-8601=seconds)",
  "hostname": "$(discover_hostname)",
  "user": "$(discover_user)",
  "kernel": "$(discover_kernel)",
  "architecture": "$(discover_architecture)",
  "desktop": "$(discover_desktop)",
  "session": "$(discover_session)",
  "window_manager": "$(discover_window_manager)"
}
EOF

}
