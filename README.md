# ArchClone

> A modular backup framework for Arch Linux.

ArchClone is a plugin-based backup and restore framework written in Bash that helps you preserve your Linux environment, configuration, packages, themes, fonts, wallpapers, and other essential data.

---

## Features

- Plugin-based backup architecture
- Backup and restore support
- SHA-256 checksum verification
- Compressed `.tar.zst` archives
- Automatic manifest generation
- Logging system
- Package inventory export
- Modular design
- Easy to extend

---

## What gets backed up?

- Hyprland
- Waybar
- Rofi
- Kitty
- Alacritty
- Fastfetch
- GTK themes
- Icon themes
- Fonts
- Wallpapers
- Shell configuration
- Package lists
- Git configuration
- MIME associations

---

## Installation

```bash
git clone git@github.com:a4ace1/ArchClone.git
cd ArchClone
./install.sh
```

---

## Usage

### Backup

```bash
./backup.sh <destination-directory>
```

Everything is staged on a local filesystem first; only the finished
archive (`archclone-<hostname>-<timestamp>.tar.zst`, plus a `.sha256`
sidecar) is ever written into `<destination-directory>`. This is
deliberate: it's what makes backing up directly onto an exFAT, FAT32,
or NTFS drive work correctly, since those filesystems can't store the
symlinks and extended attributes ArchClone backups rely on, and never
have to -- they only ever see one opaque file.

```bash
./backup.sh /mnt/my-backup-drive
```

### Restore

```bash
./restore.sh <backup-directory-or-archive> [options]
```

Accepts either:
- a compressed archive produced by `backup.sh` (`.tar.zst`, `.tar.gz`/`.tgz`, or `.tar`), or
- an already-extracted backup directory (one containing `manifest.json`).

Options:

| Option | Effect |
|---|---|
| `-y`, `--yes` | Skip the confirmation prompt. Required for non-interactive/CI use (or set `ARCHCLONE_YES=1`). |
| `--home <dir>` | Restore into `<dir>` instead of `$HOME`. |

When given an archive, restore:

1. Estimates the uncompressed size and checks free space at the
   extraction location *before* extracting, failing with an actionable
   message (target path, filesystem, estimated need vs. available) if
   there isn't enough room, rather than failing partway through.
2. Extracts into `$HOME/.cache/archclone/restore` by default. Override
   with `ARCHCLONE_RESTORE_TMPDIR=/some/other/path` if you'd rather
   extract somewhere else (a drive with more free space, for example).
3. Verifies the backup's checksums before restoring anything.
4. Prompts for confirmation (unless `--yes`/`ARCHCLONE_YES=1`), since
   restoring overwrites files under the target home directory.
5. Runs each restore module (dotfiles, fonts, icons, packages, themes,
   wallpapers).
6. Runs a post-restore verification pass and prints a summary --
   spot-checking that restored dotfiles actually landed where
   expected, and reporting file counts for the other categories. A
   restore module returning success only means it ran without error;
   this step is what confirms content actually arrived.

```bash
# Typical: restore straight from the archive on the backup drive
./restore.sh /mnt/my-backup-drive/archclone-myhost-2026-01-15-120000.tar.zst

# Non-interactive (CI, scripts, fresh-install automation)
./restore.sh /mnt/my-backup-drive/archclone-myhost-2026-01-15-120000.tar.zst --yes

# Restore into a different home directory
./restore.sh backup.tar.zst --home /home/otheruser
```

### Verify

```bash
./verify.sh <backup-directory-or-archive>
```

### Diagnostics

```bash
./doctor.sh
```

---

## Project Structure

```
ArchClone/
├── backup.sh
├── restore.sh
├── verify.sh
├── doctor.sh
├── install.sh
├── lib/
├── modules/
├── config/
├── tests/
└── README.md
```

---

## Architecture

ArchClone follows a plugin-based architecture.

Each module is responsible for backing up a specific component of the system.

Examples:

- Dotfiles
- Fonts
- Packages
- Themes
- Wallpapers
- Icons

Adding new modules requires no modification to the backup engine.

---

## Requirements

- Arch Linux
- Bash
- tar
- zstd
- sha256sum

---

## Roadmap

- [x] Plugin system
- [x] Restore engine
- [x] Checksum verification
- [x] Archive generation
- [x] Logging
- [ ] Incremental backups
- [ ] Encryption
- [ ] Cloud synchronization

---

## Author

Designed & Developed by

**S. Abubakar**

GitHub: https://github.com/a4ace1

Handle: **@a4ace_1**

---

## License

MIT License
