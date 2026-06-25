#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

create_archive() {

    local source_dir="$1"
    local output_file="$2"

    info "Creating compressed archive..."

    tar \
        --zstd \
        -cf "$output_file" \
        -C "$(dirname "$source_dir")" \
        "$(basename "$source_dir")"

    success "Archive created:"
    success "$output_file"
}
