#!/bin/sh
# platform: macOS-only -- pkgbuild and productbuild assemble the pkg
#   usage: UPD_APP=APP VERSION=V [STAGE=DIR] [OUT=DIR] sh build/package-pkg.sh
#          Compat-guards the dylibs, gives the staged tree its manifest, updater and install scripts,
#          and wraps it with the 10.9.5 floor. Prints the .pkg path.
set -eu
SELF="$(cd "$(dirname "$0")" && pwd)"
MLS_ROOT="$(cd "$SELF/.." && pwd)"; export MLS_ROOT
. "$SELF/lib.sh"

: "${MAVERICKS_BUILD_ROOT:=${TMPDIR:-/tmp}/mm-build}"
STAGE="${STAGE:-$MAVERICKS_BUILD_ROOT/stage}"
OUT="${OUT:-$MAVERICKS_BUILD_ROOT/out}"
: "${UPD_APP:?package-pkg: UPD_APP (built updater .app) required}"
: "${VERSION:?package-pkg: VERSION (full version) required}"
SCRIPTS="$(msc_scripts)"
ID="dev.mavergreen.macports-legacy-support"
TREE="$STAGE/usr/local/mavergreen/legacysupport"
mkdir -p "$OUT"

sh "$SCRIPTS/assert_binary_compatible.sh" \
  "$TREE/lib/libMacportsLegacySupport.dylib" \
  "$TREE/lib/libMacportsLegacySystem.B.dylib" >&2

SCR="$OUT/pkg-scripts"; rm -rf "$SCR"
sh "$SCRIPTS/stage_product.sh" --stage "$STAGE" --product legacysupport \
  --name "MacPorts legacy-support for Mavericks" --version "$VERSION" --updater-app "$UPD_APP" \
  --postinstall-hook "$MLS_ROOT/packaging/postinstall-hook.sh" --scripts-out "$SCR" >&2

mkdir -p "$OUT/component"
comp="$OUT/component/macports-legacy-support-component.pkg"
pkgbuild --root "$STAGE" --identifier "$ID" --version "$VERSION" --scripts "$SCR" \
  --install-location / "$comp" >&2

final="$OUT/macports-legacy-support-${VERSION}.pkg"
sh "$SCRIPTS/set_install_floor.sh" --identifier "$ID" --title "MacPorts legacy-support ${VERSION}" \
  --component "$comp" --out "$final" --host-arch x86_64 --require-scripts >&2

printf '%s\n' "$final"
