#!/bin/sh
# The flag-day migration (2026-09-22, ModernMavericks -> Mavergreen) in packaging/postinstall:
#   1. it forgets the pre-rename receipt on Installer's target volume, only there, and never fails
#      the install;
#   2. the agent-load.sh it sources retires the OLD updater .app + update-check agent. That logic is
#      shipyard's (updater/agent-load.in), but it works only if the postinstall sources it with its own
#      positional args intact and the new label is the old one with the prefix swapped -- this repo's to
#      get right. The old names below are what the pre-flag-day pkg actually installed;
#   3. the updater icon swap lands on the target volume's updater, at its new path.
# pkgutil, launchctl and sudo are PATH stubs that record their arguments, and everything happens under
# a fake volume, so nothing here touches a real receipt database, /Library or a launchd session.
# DELETABLE with the migration block in packaging/postinstall (shipyard SKILL.md "Consolidation
# backlog").
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
t="$(mktemp -d "${TMPDIR:-/tmp}/flagday.XXXXXX")"   # template: 10.9 BSD mktemp requires one
trap 'rm -rf "$t"' EXIT
fail() { echo "FAIL: $*"; exit 1; }
OLD_ID=dev.modernmavericks.macports-legacy-support
OLD_LABEL=dev.modernmavericks.macports-legacy-support-updatecheck
APP=LegacySupportUpdater.app

mkdir -p "$t/bin" "$t/scripts"
for cmd in pkgutil launchctl sudo; do
  cat > "$t/bin/$cmd" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$t/$cmd.log"
exit \${STUB_RC:-0}
EOF
  chmod +x "$t/bin/$cmd"
done
cp "$ROOT/packaging/postinstall" "$t/scripts/postinstall"

# --- 1. the receipt (no agent-load.sh beside the script: that half is optional there) -------------
mkdir -p "$t/vol"
# Installer runs postinstall as: $1 pkg path, $2 install location, $3 target volume, $4 system root.
PATH="$t/bin:$PATH" sh "$t/scripts/postinstall" /x.pkg / "$t/vol" / || fail "postinstall failed"
[ "$(cat "$t/pkgutil.log")" = "--volume $t/vol --forget $OLD_ID" ] \
  || fail "expected the old receipt forgotten on the target volume, got: $(cat "$t/pkgutil.log")"

# A pkgutil that fails (no such receipt: every fresh install) must not fail the install.
rm -f "$t/pkgutil.log"
PATH="$t/bin:$PATH" STUB_RC=1 sh "$t/scripts/postinstall" /x.pkg / "$t/vol" / || fail "a failing pkgutil failed the install"

# No target volume: nothing is known about where an old install lives, so nothing is done.
rm -f "$t/pkgutil.log"
PATH="$t/bin:$PATH" sh "$t/scripts/postinstall" || fail "postinstall with no args failed"
[ ! -f "$t/pkgutil.log" ] || fail "pkgutil ran with no target volume: $(cat "$t/pkgutil.log")"

# --- 2. + 3. the old updater + agent, and the icon ------------------------------------------------
# SHIPYARD_SCRIPTS is what CI packages with (install@v1 exports it), so it is what must retire the
# old updater. Unset (a plain local run), there is no shipyard to render with: skip this half.
if [ -z "${SHIPYARD_SCRIPTS:-}" ] || [ ! -f "$SHIPYARD_SCRIPTS/stage_updater.sh" ]; then
  echo "OK: flag-day postinstall (SHIPYARD_SCRIPTS unset: skipped the updater-retirement half)"
  exit 0
fi
label="$(sed -n 's/^ *--agent-label \([^ ]*\) .*/\1/p' "$ROOT/build/package-pkg.sh")"
[ "$label" = "dev.mavergreen.${OLD_LABEL#dev.modernmavericks.}" ] \
  || fail "build/package-pkg.sh stages its agent as '$label', which is not $OLD_LABEL under the new prefix:
      the shared retirement derives the old label from the new one, so it would miss the old agent"
grep -q "/$APP\"" "$ROOT/tests/package-pkg.sh" || fail "the updater is no longer $APP; update this test with it"

mkdir -p "$t/$APP/Contents/MacOS"
sh "$SHIPYARD_SCRIPTS/stage_updater.sh" --stage "$t/stage" --app "$t/$APP" \
  --app-dir "/Library/Application Support/Mavergreen" --agent-label "$label" \
  --snippet-out "$t/scripts/agent-load.sh" 2>/dev/null || fail "stage_updater.sh failed"

V="$t/vol2"; OLDAPPS="$V/Library/Application Support/ModernMavericks"
NEWICON="$V/Library/Application Support/Mavergreen/$APP/Contents/Resources/macports-legacy-support-updater.icns"
mkdir -p "$V/Library/LaunchAgents" "$OLDAPPS/$APP/Contents/MacOS" "$(dirname "$NEWICON")"
touch "$V/Library/LaunchAgents/$OLD_LABEL.plist" "$OLDAPPS/$APP/Contents/MacOS/x"
printf 'placeholder\n' > "$NEWICON"
PATH="$t/bin:$PATH" sh "$t/scripts/postinstall" /x.pkg / "$V" / || fail "postinstall failed"
if [ -f "$V/Library/LaunchAgents/$OLD_LABEL.plist" ] || [ -d "$OLDAPPS/$APP" ]; then
  fail "the postinstall left the old updater behind ($OLD_LABEL, $APP). A shipyard at
      $SHIPYARD_SCRIPTS that predates the flag day retires nothing: package with one released after it."
fi
CORETYPES=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources
if [ -f "$CORETYPES/GenericFrameworkIcon.icns" ] || [ -f "$CORETYPES/LibraryFolderIcon.icns" ] || [ -f "$CORETYPES/KEXT.icns" ]; then
  [ "$(cat "$NEWICON")" != placeholder ] || fail "the icon swap did not reach the target volume's updater"
fi
echo "OK: flag-day postinstall + old updater retirement + icon on the target volume"
