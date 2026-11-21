#!/usr/bin/env sh
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
cd "$PROJECT_ROOT"

swift build -c release --arch arm64
BIN_DIR=$(swift build -c release --arch arm64 --show-bin-path)

APP="$PROJECT_ROOT/build/Chytanka.app"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/chytanka" "$APP/Contents/MacOS/chytanka"
cp "$PROJECT_ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp "$PROJECT_ROOT/Resources/cmudict.dict" "$PROJECT_ROOT/Resources/cmudict-LICENSE" "$APP/Contents/Resources/"
cp -R "$PROJECT_ROOT/Resources/uk.lproj" "$APP/Contents/Resources/"
cp "$PROJECT_ROOT/install.sh" "$APP/Contents/Resources/install.sh"
codesign --force --sign - "$APP"

# An ad-hoc signature changes with every build, so an old Accessibility grant
# stays visible in System Settings but no longer applies. Reset it to get a fresh prompt.
tccutil reset Accessibility com.ihororlovskyi.chytanka >/dev/null 2>&1 || true

echo "$APP"
