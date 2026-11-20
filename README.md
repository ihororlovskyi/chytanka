# Chytanka

Tiny macOS menu bar app that reads the selected text aloud in Ukrainian.

Select text in any app and press **Option-Escape**. Press it again to stop.
Latin-script words can go to an English system voice (menu toggle); by default
the Ukrainian voice reads everything.

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

The app is ad-hoc signed, so macOS asks for Accessibility again after each
rebuild: remove the old Chytanka entry in System Settings → Privacy & Security →
Accessibility and add the new build.

## Versioning

Versions are plain `0.0.1`, `0.0.2`, ... without a `v` prefix; only the patch
component grows.
