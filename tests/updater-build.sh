#!/bin/sh
# platform: macOS-only -- otool inspects the built updater's linked libraries
set -eu
cd "$(dirname "$0")/.."
tmp="$(mktemp -d "${TMPDIR:-/tmp}/updater-build.XXXXXX")"   # template: 10.9 BSD mktemp requires one
# shipyard-cmake IS the shipyard: it finds MavericksShipyard in its own prefix, which is why this
# needs no registry, no CMAKE_PREFIX_PATH and no probing. Without it nothing can configure this
# project at all, so skip (77) rather than fail. The sibling-checkout tier this used to have is gone
# with the registry it wrote: a `--install` of a sibling working copy now lands somewhere no cmake
# looks, and a box with no shipyard pkg has no shipyard-cmake to point at it anyway. See the README's
# "Install (once)"; to test against a shipyard you are developing, install it to a prefix of your own
# and run this with CMAKE_PREFIX_PATH set to it.
SC="$(command -v shipyard-cmake || echo /usr/local/mavergreen/bin/shipyard-cmake)"; [ -x "$SC" ] || { echo "no shipyard-cmake -- skipping" >&2; exit 77; }
# msc.sh gives us SHIPYARD_SCRIPTS to point at MavericksToolchain.cmake: the toolchain-file backstop
# FATAL_ERRORs a configure whose sysroot isn't the pinned SDK, and a bare shipyard-cmake call sets none.
. build/msc.sh || { echo "msc.sh could not locate shipyard -- skipping" >&2; exit 77; }
# A shipyard older than its toolchain file is found but cannot configure this project: a stale
# install, not a platform limit, so fail and say so rather than skip.
[ -f "$SHIPYARD_SCRIPTS/../MavericksToolchain.cmake" ] \
  || { echo "the shipyard at $SHIPYARD_SCRIPTS predates MavericksToolchain.cmake -- install the current shipyard pkg" >&2; exit 1; }

printf '1.5.2-mavericks.1\n' > VERSION
B="$tmp/updater"
"$SC" -S . -B "$B" -DCMAKE_OBJC_COMPILER=/usr/bin/clang \
  -DCMAKE_TOOLCHAIN_FILE="$SHIPYARD_SCRIPTS/../MavericksToolchain.cmake" >/dev/null
"$SC" --build "$B" --target legacysupport-updater >/dev/null
bin="$B/legacysupport-updater.app/Contents/MacOS/legacysupport-updater"
[ -x "$bin" ] || { echo "updater binary missing"; exit 1; }
! otool -L "$bin" | grep -qi MacportsLegacySupport || { echo "updater links the library it updates"; exit 1; }
echo "updater-build OK"
