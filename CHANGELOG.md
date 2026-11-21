# Changelog

## 0.0.4 - 2026-11-21

### Added

- English words are transliterated into Ukrainian letters by default, using the
  CMU Pronouncing Dictionary, so the Ukrainian voice reads them close to English.
- Voice menu: pick any installed Ukrainian voice, such as Lesya or Lesya
  (Enhanced). The best installed one is the default.
- Launch at Login and About Chytanka menu items.
- Update check against GitHub releases, with a Download and Install menu item.
- `install.sh update` and `install.sh uninstall`.
- npm package: `npx chytanka install`, `update`, `uninstall`.
- MIT license.
- English menu and alerts; Ukrainian when it is the preferred system language.

### Removed

- The English voice option for Latin-script words.

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
