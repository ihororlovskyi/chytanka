# Changelog

## 0.0.3 - 2026-11-21

### Added

- `install.sh` and a Homebrew cask in `ihororlovskyi/tap`.
- Alert with a link to the Accessibility settings when the permission is missing.
- Logs under the `com.ihororlovskyi.chytanka` subsystem.

### Fixed

- Reading silently did nothing after a rebuild: the build script now resets the
  stale Accessibility grant.

## 0.0.2 - 2026-11-21

### Changed

- Hot key is now Control-Escape, so it no longer clashes with the macOS
  built-in Speak Selection shortcut Option-Escape.

## 0.0.1 - 2026-11-21

### Added

- Menu bar app that reads the selected text aloud with the Ukrainian system voice.
- Global hot key Option-Escape: read the selection, press again to stop.
- Optional English voice for Latin-script words.
