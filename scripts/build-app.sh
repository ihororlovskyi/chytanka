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
codesign --force --sign - "$APP"

echo "$APP"
