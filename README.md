# Chytanka

Tiny macOS menu bar app that reads the selected text aloud in Ukrainian.

Select text in any app and press **Control-Escape**. Press it again to stop.
Latin-script words can go to an English system voice (menu toggle); by default
the Ukrainian voice reads everything.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/ihororlovskyi/chytanka/main/install.sh | sh
```

Or with Homebrew:

```sh
brew tap ihororlovskyi/tap
brew trust --cask ihororlovskyi/tap/chytanka
brew install --cask chytanka
```

The app is ad-hoc signed. After a Homebrew install, open it once from
`/Applications` with right-click → Open. Then allow it in System Settings →
Privacy & Security → Accessibility.

## Requirements

- macOS 14+, Apple Silicon.
- The Ukrainian system voice (Lesya): System Settings → Accessibility →
  Spoken Content → System Voice → Manage Voices.
- Accessibility permission, used to read the selection.

## Build

```sh
swift test
./scripts/build-app.sh   # prints the path to build/Chytanka.app
open build/Chytanka.app
```

The app is ad-hoc signed, so an Accessibility grant does not survive a rebuild.
`build-app.sh` resets it, and the next launch asks again. When reading does
nothing, the app shows an alert that opens the Accessibility settings.

Logs: `log stream --predicate 'subsystem == "com.ihororlovskyi.chytanka"'`.

## Versioning

Versions are plain `0.0.1`, `0.0.2`, ... without a `v` prefix; only the patch
component grows.
