#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
TMP="$(mktemp -d "${TMPDIR:-/tmp}/build-lib.XXXXXX")"; trap 'rm -rf "$TMP"' EXIT   # template: 10.9 BSD mktemp requires one
STAGE="$TMP/stage"
sh build/build-lib.sh "$STAGE" >/dev/null   # build-lib.sh fetches the pinned 10.9 SDK itself
lib="$STAGE/usr/local/lib"
for f in libMacportsLegacySupport.a libMacportsLegacySupport.dylib; do
  [ -f "$lib/$f" ] || { echo "missing $f"; exit 1; }
done
[ "$(lipo -info "$lib/libMacportsLegacySupport.dylib" | sed -n 's/.*: //p' | xargs)" = x86_64 ] || { echo "dylib not x86_64-only"; exit 1; }
otool -l "$lib/libMacportsLegacySupport.dylib" | grep -A2 LC_VERSION_MIN_MACOSX | grep -q 'version 10.9' \
  || { echo "dylib min is not 10.9"; exit 1; }
[ -d "$STAGE/usr/local/include/LegacySupport" ] || { echo "headers not installed"; exit 1; }
echo "build-lib OK"
