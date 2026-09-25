# platform: host-agnostic
setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TMP="$(mktemp -d "${TMPDIR:-/tmp}/version-bats.XXXXXX")"   # template: 10.9 BSD mktemp requires one
  printf '1.5.2\n' > "$TMP/UPSTREAM_VERSION"
  mkdir -p "$TMP/build"
  # Copy the WHOLE scaffolding, not a named subset: version.sh is a thin wrapper that sources
  # msc.sh to locate the shared implementation, so cherry-picking files silently breaks it.
  cp "$REPO"/build/*.sh "$TMP/build/"
}
teardown() { rm -rf "$TMP"; }
run_ver() { ( cd "$TMP" && MAVERICKS_TAGS="$1" sh build/version.sh "$2" ); }

@test "auto, no prior tags -> mavericks.1, release" {
  run run_ver "" auto
  [ "$status" -eq 0 ]
  [[ "$output" == *"FULL=1.5.2-mavericks.1"* ]] || false
  [[ "$output" == *"TAG=1.5.2-mavericks.1"* ]] || false
  [[ "$output" == *"RELEASE=yes"* ]] || false
}
@test "auto, current upstream already released -> no release" {
  run run_ver "1.5.2-mavericks.1" auto
  [[ "$output" == *"FULL=1.5.2-mavericks.1"* ]] || false
  [[ "$output" == *"RELEASE=no"* ]] || false
}
@test "auto, picks max existing rev" {
  run run_ver "$(printf '1.5.2-mavericks.1\n1.5.2-mavericks.2')" auto
  [[ "$output" == *"FULL=1.5.2-mavericks.2"* ]] || false
  [[ "$output" == *"RELEASE=no"* ]] || false
}
@test "auto, upstream bumped -> reset to mavericks.1, release" {
  ( cd "$TMP" && printf '1.6.0\n' > UPSTREAM_VERSION )
  run run_ver "$(printf '1.5.2-mavericks.1\n1.5.2-mavericks.2')" auto
  [[ "$output" == *"FULL=1.6.0-mavericks.1"* ]] || false
  [[ "$output" == *"RELEASE=yes"* ]] || false
}
@test "local, increments past max rev" {
  run run_ver "$(printf '1.5.2-mavericks.1\n1.5.2-mavericks.2')" local
  [[ "$output" == *"FULL=1.5.2-mavericks.3"* ]] || false
  [[ "$output" == *"RELEASE=yes"* ]] || false
}
@test "local, no prior tags -> mavericks.1" {
  run run_ver "" local
  [[ "$output" == *"FULL=1.5.2-mavericks.1"* ]] || false
}
@test "bad mode fails" {
  run run_ver "" bogus
  [ "$status" -ne 0 ]
}
