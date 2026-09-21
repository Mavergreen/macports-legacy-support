#!/bin/sh
# Compat-guard the shipped dylibs, fold in the Sparkle updater + LaunchAgent,
# pkgbuild a component, then productbuild it with a hard 10.9.5 install floor.
set -eu
SELF="$(cd "$(dirname "$0")" && pwd)"
MLS_ROOT="$(cd "$SELF/.." && pwd)"; export MLS_ROOT
. "$SELF/lib.sh"

# spec: claude-plugins/modernmavericks/skills/modernmavericks-conventions/SKILL.md
#       "Build OUT of the source tree, onto fast local storage" -- CI exports
#       MAVERICKS_BUILD_ROOT itself; this default only covers a plain local run.
: "${MAVERICKS_BUILD_ROOT:=${TMPDIR:-/tmp}/mm-build}"
STAGE="${STAGE:-$MAVERICKS_BUILD_ROOT/stage}"
OUT="${OUT:-$MAVERICKS_BUILD_ROOT/out}"
: "${UPD_APP:?package-pkg: UPD_APP (built updater .app) required}"
: "${VERSION:?package-pkg: VERSION (full version) required}"
SCRIPTS="$(msc_scripts)"
ID="dev.modernmavericks.macports-legacy-support"
mkdir -p "$OUT"

# 1) prove the shipped runtime is 10.9-safe (x86_64 + min-10.9 + no post-10.9 imports).
sh "$SCRIPTS/assert_binary_compatible.sh" \
  "$STAGE/usr/local/lib/libMacportsLegacySupport.dylib" \
  "$STAGE/usr/local/lib/libMacportsLegacySystem.B.dylib" >&2

# 2) fold the updater .app + daily-check LaunchAgent into the payload. We ship our OWN postinstall
#    (it also borrows the system framework icon), so take the agent-load logic as a snippet and let
#    our script source it -- one implementation of that logic across every product.
SCR="$OUT/pkg-scripts"; rm -rf "$SCR"; mkdir -p "$SCR"
cp "$MLS_ROOT/packaging/postinstall" "$SCR/postinstall"; chmod +x "$SCR/postinstall"
sh "$SCRIPTS/stage_updater.sh" \
  --stage "$STAGE" \
  --app "$UPD_APP" \
  --app-dir "/Library/Application Support/ModernMavericks" \
  --agent-label dev.modernmavericks.macports-legacy-support-updatecheck \
  --snippet-out "$SCR/agent-load.sh"

# 3) flat component pkg from the staging root (absolute layout -> install-location /).
mkdir -p "$OUT/component"
comp="$OUT/component/macports-legacy-support-component.pkg"
pkgbuild --root "$STAGE" --identifier "$ID" --version "$VERSION" \
  --scripts "$SCR" --install-location / "$comp" >&2

# 4) wrap with the 10.9.5 floor; require-scripts because postinstall loads the agent.
final="$OUT/macports-legacy-support-${VERSION}.pkg"
sh "$SCRIPTS/set_install_floor.sh" \
  --identifier "$ID" \
  --title "MacPorts legacy-support ${VERSION}" \
  --component "$comp" \
  --out "$final" \
  --host-arch x86_64 \
  --require-scripts >&2

printf '%s\n' "$final"
