#!/bin/bash
set -euo pipefail

xcframework=${1:?Missing XCFramework path}
architecture=${2:?Missing architecture}
plist="$xcframework/Info.plist"

index=0
while platform=$(/usr/libexec/PlistBuddy -c "Print :AvailableLibraries:$index:SupportedPlatform" "$plist"); do
    [[ $platform != macos ]] || break
    index=$((index + 1))
done
[[ ${platform:-} == macos ]]

key=":AvailableLibraries:$index"
identifier=$(/usr/libexec/PlistBuddy -c "Print $key:LibraryIdentifier" "$plist")
slice="$xcframework/$identifier"

# Thin both binaries before signing, preserving their matching UUIDs.
for binary in \
    "$slice/PartoutNative.framework/Versions/A/PartoutNative" \
    "$slice/dSYMs/PartoutNative.framework.dSYM/Contents/Resources/DWARF/PartoutNative"; do
    if [[ $(lipo -archs "$binary") != "$architecture" ]]; then
        lipo "$binary" -thin "$architecture" -output "$binary"
    fi
done

/usr/libexec/PlistBuddy \
    -c "Delete $key:SupportedArchitectures" \
    -c "Add $key:SupportedArchitectures array" \
    -c "Add $key:SupportedArchitectures:0 string $architecture" "$plist"
echo "Prepared macOS XCFramework and dSYM for $architecture"
