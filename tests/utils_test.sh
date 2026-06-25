#!/usr/bin/env bash

set -Eeuo pipefail

source lib/utils.sh

echo "== ArchForge Utils Test =="

command_exists bash && echo "✔ command_exists"

file_exists lib/utils.sh && echo "✔ file_exists"

directory_exists lib && echo "✔ directory_exists"

ensure_directory temp_test

directory_exists temp_test && echo "✔ ensure_directory"

rm -rf temp_test

echo "Human size:"
human_size 1073741824

echo "All tests passed!"
