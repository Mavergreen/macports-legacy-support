#!/bin/sh
# platform: host-agnostic
set -eu
cd "$(dirname "$0")/.."
fail=0
grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' UPSTREAM_VERSION || { echo "UPSTREAM_VERSION not a bare x.y.z"; fail=1; }
for pat in '^/VERSION$' '^build/$' '^dist/$'; do
  grep -Eq "$pat" .gitignore || { echo ".gitignore missing $pat"; fail=1; }
done
# The icon is named for the repo, which was renamed to macports-legacy-support; this assertion kept
# checking the old filename, and nothing ran it to notice. Glob so a future rename fails loudly on
# "no icon found" rather than passing silently.
icns=$(ls updater/*.icns 2>/dev/null | head -1)
[ -n "$icns" ] || { echo "no .icns in updater/"; fail=1; }
[ -z "$icns" ] || file "$icns" | grep -qi 'icon' || { echo "$icns is not a valid icon"; fail=1; }
[ "$fail" = 0 ] && echo "skeleton OK"
exit $fail
