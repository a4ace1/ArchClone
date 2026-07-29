#!/usr/bin/env bash

set -Eeuo pipefail


generate_checksums() {

    local backup_root="$1"

    info "Generating SHA256 checksums..."

    (
        cd "$backup_root"

        # checksums.sha256 is excluded by name in the find filter above,
        # so truncating it via the `>` redirect before find/sort/xargs
        # run is safe: its old content is never read.
        # shellcheck disable=SC2094
        find . -type f \
            ! -name checksums.sha256 \
            ! -name archclone.log \
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

    if [[ ! -f "$backup_root/checksums.sha256" ]]; then
        error "checksums.sha256 not found in: $backup_root"
        return 1
    fi

    if (
        cd "$backup_root"
        sha256sum -c checksums.sha256
    ); then
        success "Verification complete."
        return 0
    else
        error "Checksum verification FAILED — one or more files are missing or modified."
        return 1
    fi
}
