#!/usr/bin/env sh
# Installs, updates, or removes Chytanka in /Applications.
#
#   sh install.sh [install [VERSION]]   latest release, or VERSION
#   sh install.sh update                latest release, if newer than the installed one
#   sh install.sh uninstall             app, settings, and Accessibility grant
set -e

REPO="ihororlovskyi/chytanka"
APP="/Applications/Chytanka.app"
BUNDLE_ID="com.ihororlovskyi.chytanka"
COMMAND=${1:-install}

if [ -d /opt/homebrew/Caskroom/chytanka ] || [ -d /usr/local/Caskroom/chytanka ]; then
  echo "Chytanka is managed by Homebrew. Use:" >&2
  echo "  brew upgrade --cask chytanka" >&2
  echo "  brew uninstall --zap --cask chytanka" >&2
  exit 1
fi

installed_version() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || true
}

# True when $1 is a newer dotted version than $2.
is_newer() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1)" = "$1" ]
}

latest_version() {
  curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p'
}

install_version() {
  VERSION=$1
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT

  echo "Downloading Chytanka $VERSION"
  curl -fsSL -o "$TMP/Chytanka.zip" \
    "https://github.com/$REPO/releases/download/$VERSION/Chytanka-$VERSION.zip"
  ditto -x -k "$TMP/Chytanka.zip" "$TMP"

  pkill -x chytanka 2>/dev/null || true
  rm -rf "$APP"
  ditto "$TMP/Chytanka.app" "$APP"
  xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

  # Each release has a new ad-hoc signature, so an old Accessibility grant no longer applies.
  tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1 || true

  open "$APP"
  echo "Installed Chytanka $VERSION. Allow it in System Settings → Privacy & Security → Accessibility."
}

case "$COMMAND" in
  install)
    VERSION=${2:-$(latest_version)}
    if [ -z "$VERSION" ]; then
      echo "Could not find the latest Chytanka release" >&2
      exit 1
    fi
    install_version "$VERSION"
    ;;
  update)
    VERSION=$(latest_version)
    if [ -z "$VERSION" ]; then
      echo "Could not find the latest Chytanka release" >&2
      exit 1
    fi
    CURRENT=$(installed_version)
    if [ -n "$CURRENT" ] && ! is_newer "$VERSION" "$CURRENT"; then
      echo "Chytanka $CURRENT is up to date (latest release: $VERSION)."
      exit 0
    fi
    install_version "$VERSION"
    ;;
  uninstall)
    pkill -x chytanka 2>/dev/null || true
    rm -rf "$APP"
    defaults delete "$BUNDLE_ID" >/dev/null 2>&1 || true
    tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1 || true
    echo "Removed Chytanka."
    ;;
  *)
    echo "Usage: install.sh [install [VERSION] | update | uninstall]" >&2
    exit 1
    ;;
esac
