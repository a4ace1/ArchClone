#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

# create_archive <source_dir> <output_file>
#
# Compresses source_dir into a .tar.zst archive.
create_archive() {

    local source_dir="$1"
    local output_file="$2"

    info "Creating compressed archive..."

    # --xattrs / --acls: without these, tar silently drops extended
    # attributes and POSIX ACLs -- the same class of silent fidelity
    # loss as the symlink problem this change exists to fix, just for
    # metadata instead of link targets.
    #
    # Explicitly detach stdin (</dev/null) so tar can never block on,
    # or accidentally consume, the caller's stdin/terminal input.
    tar \
        --xattrs \
        --acls \
        --zstd \
        -cf "$output_file" \
        -C "$(dirname "$source_dir")" \
        "$(basename "$source_dir")" \
        < /dev/null

    success "Archive created:"
    success "$output_file"
}

# is_archive_file <path>
#
# Returns 0 if path looks like an ArchClone archive (.tar.zst / .tar.gz / .tgz / .tar).
is_archive_file() {
    local path="$1"

    [[ -f "$path" ]] || return 1

    case "$path" in
        *.tar.zst|*.tar.gz|*.tgz|*.tar)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# extract_archive <archive_file> <destination_dir>
#
# Extracts an ArchClone backup archive into destination_dir.
#
# IMPORTANT (stdin safety):
# tar is given an explicit archive file via -f, so it never needs to
# read from stdin to do its job. We still redirect its stdin from
# /dev/null defensively so that, no matter how this function is
# invoked (including from inside a pipeline or a `while read` loop),
# tar can never consume bytes that were meant for an interactive or
# piped confirmation prompt (e.g. `yes | ./archclone restore x.tar.zst`).
# This is what caused the historical "Please answer yes or no." /
# stuck-prompt bug: an earlier extraction step lived inside the same
# pipeline as the confirmation read, so the piped "yes" answer was
# consumed by tar/zstd instead of by `read`.
extract_archive() {
    local archive_file="$1"
    local dest_dir="$2"

    [[ -f "$archive_file" ]] || die "Archive not found: $archive_file"

    ensure_directory "$dest_dir"

    info "Extracting archive..."

    local tar_flag=""
    case "$archive_file" in
        *.tar.zst) tar_flag="--zstd" ;;
        *.tar.gz|*.tgz) tar_flag="-z" ;;
        *.tar) tar_flag="" ;;
        *) die "Unsupported archive format: $archive_file" ;;
    esac

    # shellcheck disable=SC2086
    tar $tar_flag \
        --xattrs \
        --acls \
        -xf "$archive_file" \
        -C "$dest_dir" \
        < /dev/null

    success "Archive extracted to: $dest_dir"
}

# find_backup_root <extracted_dir>
#
# ArchClone archives are created with `tar -C "$(dirname dir)" "$(basename dir)"`,
# so extracting them yields exactly one top-level directory containing the
# actual backup contents (manifest.json, checksums.sha256, ...). This helper
# locates that directory so callers don't have to guess the original name.
find_backup_root() {
    local extracted_dir="$1"

    # Already a backup root (has a manifest)?
    if [[ -f "$extracted_dir/manifest.json" ]]; then
        printf "%s\n" "$extracted_dir"
        return 0
    fi

    local entries=()
    while IFS= read -r -d '' entry; do
        entries+=("$entry")
    done < <(find "$extracted_dir" -mindepth 1 -maxdepth 1 -type d -print0)

    if [[ ${#entries[@]} -eq 1 && -f "${entries[0]}/manifest.json" ]]; then
        printf "%s\n" "${entries[0]}"
        return 0
    fi

    die "Could not locate backup root inside extracted archive: $extracted_dir"
}

# estimate_archive_uncompressed_size <archive_file>
#
# Prints an approximate uncompressed size in bytes: the sum of file
# sizes from `tar -tv`, plus a per-file block-overhead allowance.
#
# The block-overhead term matters more than it might look: a naive
# byte-sum badly underestimates real disk usage for archives with many
# small files (exactly what a dotfiles backup is) -- most filesystems
# allocate at least one block per file regardless of its actual size,
# so ten 200-byte config files can consume 40KB on disk, not 2KB. A
# flat percentage safety margin doesn't fix this because the error is
# per-file, not proportional to total size. 4096 bytes/file is a
# reasonable common-case block size; this is still an estimate, not an
# exact figure, but it's the term that was missing before.
estimate_archive_uncompressed_size() {
    local archive_file="$1"

    local tar_flag=""
    case "$archive_file" in
        *.tar.zst) tar_flag="--zstd" ;;
        *.tar.gz|*.tgz) tar_flag="-z" ;;
        *.tar) tar_flag="" ;;
        *) die "Unsupported archive format: $archive_file" ;;
    esac

    # shellcheck disable=SC2086
    tar $tar_flag -tvf "$archive_file" < /dev/null 2>/dev/null \
        | awk '{
            sum += $3
            files += 1
          }
          END {
            block_overhead = files * 4096
            print sum + block_overhead
          }'
}
