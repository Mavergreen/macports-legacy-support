#!/bin/sh
# platform: macOS-only -- xcrun resolves the SDK, and lipo/otool inspect the built Mach-O dylibs
set -eu
cd "$(dirname "$0")/.."
TMP="$(mktemp -d "${TMPDIR:-/tmp}/build-lib.XXXXXX")"; trap 'rm -rf "$TMP"' EXIT   # template: 10.9 BSD mktemp requires one
STAGE="$TMP/stage"
sh build/build-lib.sh "$STAGE" >/dev/null   # build-lib.sh fetches the pinned 10.9 SDK itself
lib="$STAGE/usr/local/mavergreen/legacysupport/lib"
for f in libMacportsLegacySupport.a libMacportsLegacySupport.dylib; do
  [ -f "$lib/$f" ] || { echo "missing $f"; exit 1; }
done
[ "$(lipo -info "$lib/libMacportsLegacySupport.dylib" | sed -n 's/.*: //p' | xargs)" = x86_64 ] || { echo "dylib not x86_64-only"; exit 1; }
otool -l "$lib/libMacportsLegacySupport.dylib" | grep -A2 LC_VERSION_MIN_MACOSX | grep -q 'version 10.9' \
  || { echo "dylib min is not 10.9"; exit 1; }
[ -d "$STAGE/usr/local/mavergreen/legacysupport/include/LegacySupport" ] || { echo "headers not installed"; exit 1; }
for f in libMacportsLegacySupport.dylib libMacportsLegacySystem.B.dylib; do
  [ "$(otool -D "$lib/$f" | sed -n 2p)" = "/usr/local/mavergreen/legacysupport/lib/$f" ] \
    || { echo "$f's install name must be its path in the product tree: $(otool -D "$lib/$f" | sed -n 2p)"; exit 1; }
done
echo "build-lib OK"
