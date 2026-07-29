#!/usr/bin/env bash

set -Eeuo pipefail

source lib/logging.sh
source modules/packages.sh

init_logger "./logs"

rm -rf test_backup

mkdir test_backup

backup_packages "./test_backup"

echo
echo "Generated files:"
find test_backup
