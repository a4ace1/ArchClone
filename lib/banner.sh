#!/usr/bin/env bash

# ==========================================================
# ArchForge Banner Library
# ==========================================================

source "$(dirname "${BASH_SOURCE[0]}")/version.sh"

show_banner() {
cat <<EOF2

╔══════════════════════════════════════════════════════════════╗
║                         ArchForge                           ║
║              Modular Arch Linux Backup Framework            ║
║                                                              ║
║                     Version : v${ARCHFORGE_VERSION}                    ║
║                                                              ║
║            Created with ❤️ by Abubakar (@a4ace_1)            ║
║              GitHub : github.com/a4ace1                     ║
╚══════════════════════════════════════════════════════════════╝

EOF2
}
