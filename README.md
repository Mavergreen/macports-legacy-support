# mavericks-legacysupport

[macports-legacy-support](https://github.com/macports/macports-legacy-support)
as a double-clickable Sparkle-updatable .pkg for Mac OS X 10.9 Mavericks.

## Install (once)

This repo builds with [shipyard](https://github.com/Mavergreen/shipyard),
the family's shared CMake helpers. Install its pkg once:

```sh
gh release download -R Mavergreen/shipyard --pattern '*.pkg'
sudo installer -pkg mavericks-shipyard-*.pkg -target /
```

That puts `shipyard-cmake`, `shipyard-ctest` and `shipyard-cpack` in
`/usr/local/bin`. **`shipyard-cmake` is the only cmake that configures this
project.** It finds shipyard in its own prefix, so `find_package(MavericksShipyard)`
resolves with nothing to register and no `CMAKE_PREFIX_PATH` to set, and
`MavericksShipyardConfig.cmake` refuses any other cmake by name rather than
half-working. Do not clone, vendor or submodule shipyard.

CI does the same thing through `Mavergreen/shipyard/.github/actions/install@v1`.

To build the updater .app by hand:

```sh
shipyard-cmake -S . -B build/updater -DCMAKE_OBJC_COMPILER=/usr/bin/clang
shipyard-cmake --build build/updater --target LegacySupportUpdater
```

`tests/updater-build.sh` and `tests/package-pkg.sh` skip (exit 77) when
`shipyard-cmake` is not installed, since without it nothing here can be
configured.

If you are developing shipyard itself, install your working copy to a prefix of
your own and point one configure at it — shipyard's own README has the details:

```sh
CMAKE_PREFIX_PATH="$HOME/.local/opt/shipyard-dev" shipyard-cmake -S . -B build/updater
```
