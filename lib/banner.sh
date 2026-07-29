#!/usr/bin/env bash

# ==========================================================
# ArchClone Banner Library
# ==========================================================

source "$(dirname "${BASH_SOURCE[0]}")/version.sh"

show_banner() {
cat <<EOF2

╔══════════════════════════════════════════════════════════════╗
║                         ArchClone                           ║
║              Modular Arch Linux Backup Framework            ║
║                                                              ║
║                     Version : v${ARCHCLONE_VERSION}                    ║
║                                                              ║
║            Created with ❤️ by Abubakar (@a4ace_1)            ║
║              GitHub : github.com/a4ace1                     ║
╚══════════════════════════════════════════════════════════════╝

EOF2
}
