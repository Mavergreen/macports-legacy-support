#!/bin/sh
# platform: host-agnostic
# Print the URL of the release notes for one upstream macports-legacy-support version. shipyard's
# upstream-notes.sh links it from our release notes when a release ships a NEW upstream.
#   usage: upstream-release-notes-url.sh <upstream-version>      (bare: 1.5.2)
set -eu
printf 'https://github.com/macports/macports-legacy-support/releases/tag/v%s\n' "${1:?usage: upstream-release-notes-url.sh <upstream-version>}"
