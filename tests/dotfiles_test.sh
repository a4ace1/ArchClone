#!/usr/bin/env bash

set -Eeuo pipefail

source lib/logging.sh
source modules/dotfiles.sh

init_logger "./logs"

rm -rf test_backup

mkdir test_backup

backup_dotfiles "./test_backup"

echo
echo "Backup contents:"
find test_backup
