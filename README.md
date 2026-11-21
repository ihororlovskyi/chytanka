# Chytanka (Читанка)

Tiny macOS menu bar app that reads the selected text aloud in Ukrainian.

Select text in any app and press **Control-Escape**. Press it again to stop.
English words are transliterated into Ukrainian letters, so the Ukrainian
voice reads them close to English pronunciation. The menu picks the Ukrainian
voice (Lesya, or Lesya (Enhanced) once downloaded) and can launch the app at
login.

## Install, update, uninstall

With the install script:

```sh
curl -fsSL https://raw.githubusercontent.com/ihororlovskyi/chytanka/main/install.sh | sh
curl -fsSL https://raw.githubusercontent.com/ihororlovskyi/chytanka/main/install.sh | sh -s -- update
curl -fsSL https://raw.githubusercontent.com/ihororlovskyi/chytanka/main/install.sh | sh -s -- uninstall
```

With npx (or `pnpm dlx`):

```sh
npx chytanka@latest install
npx chytanka@latest update
npx chytanka@latest uninstall
```

With Homebrew:

```sh
brew tap ihororlovskyi/tap
brew trust --cask ihororlovskyi/tap/chytanka
brew install --cask chytanka
brew upgrade --cask chytanka
brew uninstall --zap --cask chytanka
```

When a newer release is out, the menu shows **Download and Install**: it
updates the app the same way it was installed (Homebrew or the install script)
and reopens it. The script and npx refuse to touch a Homebrew-managed copy.

The app is ad-hoc signed. After a Homebrew install, open it once from
`/Applications` with right-click → Open. After every install or update, allow
it again in System Settings → Privacy & Security → Accessibility.

## Requirements

- macOS 14+, Apple Silicon.
- The Ukrainian system voice (Lesya): System Settings → Accessibility →
  Spoken Content → System Voice → Manage Voices. Lesya (Enhanced) sounds more
  natural.
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

## Credits

Pronunciations come from the
[CMU Pronouncing Dictionary](https://github.com/cmusphinx/cmudict),
© Carnegie Mellon University, BSD-style license in `Resources/cmudict-LICENSE`.

## License

[MIT](LICENSE). The bundled pronunciation dictionary keeps its own license.

## Versioning

Versions are plain `0.0.1`, `0.0.2`, ... without a `v` prefix; only the patch
component grows.
