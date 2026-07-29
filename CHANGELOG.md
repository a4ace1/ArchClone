# Changelog

All notable changes to ArchForge are documented here.

## [1.0.1] - Unreleased

### Fixed

- **Version drift.** The version string was duplicated and inconsistent
  across the banner, CLI launcher, and manifest generator. There is now a
  single `VERSION` file at the project root, read once via `lib/version.sh`
  and shared by every script/module.
- **`backup.sh` crashed under strict mode with no arguments.** It now
  validates its arguments and prints a proper usage message.
- **`restore.sh` could not restore directly from an archive.** It now
  detects `.tar.zst` / `.tar.gz` / `.tgz` / `.tar` input and transparently
  extracts it to a temporary directory before restoring, in addition to
  accepting an already-extracted backup directory.
- **stdin / interactive-prompt safety (critical).** Archive extraction now
  always redirects its own stdin from `/dev/null` (`lib/archive.sh`), so it
  can never consume bytes meant for a confirmation prompt. The restore
  confirmation is the *only* place stdin is read in the whole restore flow.
  Added `-y`/`--yes` (and `ARCHFORGE_YES=1`) for non-interactive/CI use, and
  a clear error instead of a hang when stdin is neither a terminal nor a
  pipe.
- **`lib/logging.sh`** had a leftover debug block dumping `LOG_FILE`/`PWD`
  to stderr on every log call — removed. Also fixed a crash ("ambiguous
  redirect") when a log function was called before `init_logger` had set
  `LOG_FILE`.
- **Duplicated rsync logic.** Every backup/restore module now goes through
  a single shared helper (`lib/rsync_wrapper.sh`) that consistently uses
  `-aHAX` (archive mode, symlinks, ACLs, xattrs, timestamps, permissions)
  and applies `config/exclude.conf`.
- **`config/exclude.conf` was never actually applied.** All modules now
  route through the shared rsync wrapper above, so exclusions are honored
  everywhere.
- **Missing restore modules.** Added `restore/dotfiles.sh`, `restore/fonts.sh`
  (now also refreshes the font cache via `fc-cache` when available),
  `restore/icons.sh`, and `restore/themes.sh`. `restore/wallpapers.sh` and
  `restore/packages.sh` existed only as stubs/partial implementations and
  have been completed.
- **Flattened backup structure.** Previously, multiple source directories
  (e.g. `~/.fonts` and `~/.local/share/fonts`) were rsynced into the same
  destination folder, silently merging/overwriting their contents and
  losing the original location. Backups now preserve each source's full
  path relative to `$HOME` under `<backup>/home/...`, so distinct sources
  never collide and restores are deterministic.
- **Non-portable restore.** Nothing in a backup encodes an absolute,
  machine-specific home directory; restoring reads `$HOME` (or an
  explicit `--home <dir>` target) at restore time, so a backup taken on
  one machine/user restores correctly on another.
- **Discovery functions could abort the calling script under `set -e`.**
  Several `discover_*` functions (icons, themes, rofi, waybar, kitty,
  alacritty, hyprland, wallpapers, ...) ended on a test whose failure
  became the function's own non-zero return status, which aborted any
  caller running under `set -e`. Every function in `lib/discovery.sh` now
  explicitly returns 0.
- **Package restore only printed suggested commands.** `restore/packages.sh`
  now actually performs the installation (pacman/yay/flatpak/npm/pip/
  pipx/cargo), each gated on the relevant tool actually being present.
- **`pip`/`pip3` detection** was inconsistent; package export/restore now
  prefers `pip3` (the name most modern distros, including Arch, ship) and
  falls back to `pip`.
- **`verify.sh` and `doctor.sh` were stubs.** `verify.sh` now wires up the
  existing `verify_checksums` logic and validates `manifest.json` is
  present; it also accepts an archive directly. `doctor.sh` now runs real
  dependency, permission, disk-space, and environment checks.
- **`install.sh` was empty.** It now sets executable permissions, runs
  `doctor.sh`, optionally installs missing dependencies via `pacman` on
  Arch systems, and optionally symlinks the `archforge` launcher onto
  `$PATH` — all prompts fall back to a safe default instead of hanging
  when stdin isn't interactive (CI-safe).
- **`packages.sh` (backup) piped commands directly into files** under
  `set -Eeuo pipefail`; a single failing package manager call (e.g. no
  AUR packages installed) aborted the entire backup. Each export is now
  guarded and reports a warning instead of failing the whole run.
- **CI** was the default GitHub Actions placeholder template and never
  ran anything project-specific. It now runs a syntax check on every
  script, ShellCheck, the existing test suite, and a full
  backup → verify → restore smoke test (both directory and archive
  restore paths) against a throwaway `$HOME`.
- **Stale test reference.** `tests/packages_test.sh` called a function
  named `export_packages`, which doesn't exist (the function is
  `backup_packages`) — the test would have always failed with "command
  not found".

### Known limitations

- Backup format changed (see "Flattened backup structure" above): a
  backup produced by 1.0.0 is **not** restorable with 1.0.1's restore
  modules, since 1.0.0 never wrote `manifest.json`/module data in a
  restorable layout to begin with (`restore.sh` in 1.0.0 only handled
  `packages`). There is no prior working restore path to migrate from.
- Package restoration (`restore/packages.sh`) requires the relevant
  package manager (pacman, yay, flatpak, npm, pip/pip3, pipx, cargo) to
  already be present on the target system; ArchForge does not bootstrap
  package managers themselves.
- `install.sh`'s automatic dependency installation only applies on
  systems with `pacman` (Arch and Arch-based distros); on other systems,
  required tools (`tar`, `zstd`, `rsync`) must be installed manually.

## [1.0.0] - Initial stable release

- Plugin-based backup framework
- SHA-256 checksum generation
- Compressed archive generation
- Logging system
- Package inventory export
- Manifest generation
