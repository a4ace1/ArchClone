#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

generate_checksums() {

    local backup_root="$1"

    info "Generating SHA256 checksums..."

    (
        cd "$backup_root"

        find . -type f \
            ! -name checksums.sha256 \
            ! -name archforge.log \
            -print0 |
            sort -z |
            xargs -0 sha256sum \
            > checksums.sha256
    )

    success "Checksums generated."
}

verify_checksums() {

    local backup_root="$1"

    info "Verifying backup..."

    (
        cd "$backup_root"

        sha256sum -c checksums.sha256
    )

    success "Verification complete."
}
