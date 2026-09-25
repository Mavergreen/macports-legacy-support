cmake_minimum_required(VERSION 3.16)
# Builds the Cocoa/Sparkle updater .app that keeps the installed macports-legacy-support
# .pkg current. ObjC/Cocoa ONLY -- it must never link the library it updates. Built
# x86_64 / min-10.9 so it runs on the target Mavericks machine.
set(CMAKE_OSX_DEPLOYMENT_TARGET 10.9 CACHE STRING "runs on 10.9")
set(CMAKE_OSX_ARCHITECTURES x86_64 CACHE STRING "Intel-only (10.9)")

project(LegacySupportUpdater LANGUAGES OBJC)

# CORRECT shipyard usage: resolved from shipyard-cmake's own prefix -- configure this
# project with shipyard-cmake and there is nothing to register and no search path to
# set (the README's "Install (once)" says where shipyard-cmake comes from). Never
# vendored/submoduled.
find_package(MavericksShipyard REQUIRED)
include(Mavericks)          # universal umbrella: AppleClang gate + build conventions
include(MavericksSparkle)   # the Sparkle updater .app builder

# Full version written by the release workflow (or a local test) into ./VERSION (gitignored).
file(STRINGS "${CMAKE_SOURCE_DIR}/VERSION" MLS_VERSION LIMIT_COUNT 1)

mavericks_add_updater_app(
  PRODUCT legacysupport
  PRODUCT_NAME "MacPorts legacy-support (Mavericks)"
  ICON "${CMAKE_SOURCE_DIR}/updater/macports-legacy-support-updater.icns"
  VERSION "${MLS_VERSION}"
  LOG_PREFIX "MLSUpdater"
  CONFIRM_TITLE "macports-legacy-support updated"
  CONFIRM_BODY "The MacPorts legacy-support libraries in /usr/local/mavergreen/legacysupport were updated."
  RELAUNCH_MARKER "/tmp/.mavericks-legacysupport-updater-relaunched"
  # no PANE_HINT_KEY -> background-found updates post an NSUserNotification (a library, no pane)
)
