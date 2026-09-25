#!/bin/sh
# platform: host-agnostic
set -eu
cd "$(dirname "$0")/.."
D="$(mktemp -d "${TMPDIR:-/tmp}/fetch-upstream.XXXXXX")"   # template: 10.9 BSD mktemp requires one
src="$(sh build/fetch-upstream.sh "$D")"
[ -f "$src/Makefile" ] || { echo "no Makefile in $src"; exit 1; }
[ -d "$src/include" ] || { echo "no include/ in $src"; exit 1; }
rm -rf "$D"
echo "fetch-upstream OK -> $src"
