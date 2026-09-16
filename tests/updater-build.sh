#!/bin/sh
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
command -v shipyard-cmake >/dev/null 2>&1 \
  || { echo "no shipyard-cmake (install the shipyard pkg -- README 'Install (once)') -- skipping" >&2; exit 77; }

printf '1.5.2-mavericks.1\n' > VERSION
B="$tmp/updater"
shipyard-cmake -S . -B "$B" -DCMAKE_OBJC_COMPILER=/usr/bin/clang >/dev/null
shipyard-cmake --build "$B" --target LegacySupportUpdater >/dev/null
bin="$B/LegacySupportUpdater.app/Contents/MacOS/LegacySupportUpdater"
[ -x "$bin" ] || { echo "updater binary missing"; exit 1; }
! otool -L "$bin" | grep -qi MacportsLegacySupport || { echo "updater links the library it updates"; exit 1; }
echo "updater-build OK"
