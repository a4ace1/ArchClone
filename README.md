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

Create a backup

```bash
./backup.sh my-backup
```

Restore

```bash
./restore.sh my-backup
```

Verify

```bash
./verify.sh my-backup
```

Run diagnostics

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
