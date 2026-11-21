#!/usr/bin/env sh
# Installs the latest Chytanka release into /Applications.
set -e

REPO="ihororlovskyi/chytanka"
APP="/Applications/Chytanka.app"

VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
if [ -z "$VERSION" ]; then
  echo "Could not find the latest Chytanka release" >&2
  exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Chytanka $VERSION"
curl -fsSL -o "$TMP/Chytanka.zip" \
  "https://github.com/$REPO/releases/download/$VERSION/Chytanka-$VERSION.zip"
ditto -x -k "$TMP/Chytanka.zip" "$TMP"

pkill -x chytanka 2>/dev/null || true
if [ -d "$APP" ]; then
  rm -rf "$APP"
fi
ditto "$TMP/Chytanka.app" "$APP"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

# Each release has a new ad-hoc signature, so an old Accessibility grant no longer applies.
tccutil reset Accessibility com.ihororlovskyi.chytanka >/dev/null 2>&1 || true

open "$APP"
echo "Installed Chytanka $VERSION. Allow it in System Settings → Privacy & Security → Accessibility."
