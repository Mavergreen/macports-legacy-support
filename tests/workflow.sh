#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
w=.github/workflows/release.yml
# correct shipyard usage: install ONLY via the action, pinned to @v1 (Renovate's
# native github-actions manager tracks the moving major tag -- no SHA, no marker comment).
grep -Eq 'uses: Mavergreen/shipyard/\.github/actions/install@v1' "$w" \
  || { echo "install action not pinned to @v1"; exit 1; }
grep -q 'cmake --install' "$w" && { echo "must NOT hand-install shipyard in CI"; exit 1; }
grep -q 'submodule' "$w" && { echo "must NOT submodule shipyard"; exit 1; }
grep -q 'build/version.sh' "$w" || { echo "workflow must derive version via build/version.sh"; exit 1; }
grep -q 'build/build-lib.sh' "$w" || { echo "workflow must build the library"; exit 1; }
grep -q 'build/package-pkg.sh' "$w" || { echo "workflow must package"; exit 1; }
grep -q 'SPARKLE_PRIVATE_KEY' "$w" || { echo "workflow must sign"; exit 1; }
# Publishing is the shared workflow, not a hand-rolled step: it owns SHA256SUMS and the Release body
# and refuses an empty one. Asserting the caller is stronger than the old 'mentions gh release'.
grep -q 'publish-release.yml@v1' "$w" || { echo "workflow must publish via the shared publish-release.yml"; exit 1; }
grep -q 'gh release create' "$w" && { echo "must NOT hand-roll publishing; use publish-release.yml"; exit 1; }
grep -q 'RELEASE_NOTES.md' "$w" || { echo "the notes must travel in the artifact as RELEASE_NOTES.md"; exit 1; }
grep -q 'fetch-depth: 0' "$w" || { echo "checkout must fetch tags (fetch-depth: 0)"; exit 1; }
echo "workflow OK"
