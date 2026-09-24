#!/bin/sh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
t="$(mktemp -d "${TMPDIR:-/tmp}/postinstall.XXXXXX")"
trap 'rm -rf "$t"' EXIT
fail() { echo "FAIL: $*"; exit 1; }
APP=LegacySupportUpdater.app

V="$t/vol"
ICON="$V/Library/Application Support/Mavergreen/$APP/Contents/Resources/macports-legacy-support-updater.icns"
mkdir -p "$(dirname "$ICON")"
printf 'placeholder\n' > "$ICON"
sh "$ROOT/packaging/postinstall" /x.pkg / "$V" / || fail "postinstall failed"
CORETYPES=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources
if [ -f "$CORETYPES/GenericFrameworkIcon.icns" ] || [ -f "$CORETYPES/LibraryFolderIcon.icns" ] || [ -f "$CORETYPES/KEXT.icns" ]; then
  [ "$(cat "$ICON")" != placeholder ] || fail "the icon swap did not reach the target volume's updater"
fi
echo "OK: postinstall swaps the updater icon on the target volume"
