#!/bin/sh
# platform: host-agnostic
_icon="$ROOT/Library/Application Support/Mavergreen/legacysupport-updater.app/Contents/Resources/macports-legacy-support-updater.icns"
_coretypes="$ROOT/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources"
if [ -f "$_icon" ]; then
  for _c in GenericFrameworkIcon.icns LibraryFolderIcon.icns KEXT.icns; do
    if [ -f "$_coretypes/$_c" ]; then
      cp "$_coretypes/$_c" "$_icon" 2>/dev/null || true
      break
    fi
  done
fi
