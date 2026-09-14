#!/bin/bash
set -euo pipefail

xcframework=${1:?Missing XCFramework path}
architecture=${2:?Missing architecture}
plist="$xcframework/Info.plist"

fail() {
    echo "XCFramework thinning failed: $*" >&2
    exit 1
}

case $architecture in
    arm64|x86_64) ;;
    *) fail "unsupported architecture: $architecture" ;;
esac

# Each DMG job owns its downloaded copy. Keep the shared artifact universal.
index=0
while platform=$(/usr/libexec/PlistBuddy -c "Print :AvailableLibraries:$index:SupportedPlatform" "$plist" 2>/dev/null); do
    if [[ $platform == macos ]]; then
        break
    fi
    index=$((index + 1))
done
[[ ${platform:-} == macos ]] || fail "missing macOS library in $xcframework"

key=":AvailableLibraries:$index"
identifier=$(/usr/libexec/PlistBuddy -c "Print $key:LibraryIdentifier" "$plist")
library=$(/usr/libexec/PlistBuddy -c "Print $key:LibraryPath" "$plist")
debug_symbols=$(/usr/libexec/PlistBuddy -c "Print $key:DebugSymbolsPath" "$plist")
slice="$xcframework/$identifier"
binaries=(
    "$slice/$library/Versions/A/PartoutNative"
    "$slice/$debug_symbols/PartoutNative.framework.dSYM/Contents/Resources/DWARF/PartoutNative"
)

# Validate both before modifying either, and preserve their matching UUIDs.
for binary in "${binaries[@]}"; do
    [[ -f $binary ]] || fail "missing $binary"
    lipo "$binary" -verify_arch "$architecture" || fail "missing $architecture in $binary"
done
for binary in "${binaries[@]}"; do
    if [[ $(lipo -archs "$binary") != "$architecture" ]]; then
        lipo "$binary" -thin "$architecture" -output "$binary.thin"
        # Overwrite the existing file to retain its executable permissions.
        cat "$binary.thin" > "$binary"
        rm "$binary.thin"
    fi
done

/usr/libexec/PlistBuddy -c "Delete $key:SupportedArchitectures" "$plist"
/usr/libexec/PlistBuddy -c "Add $key:SupportedArchitectures array" "$plist"
/usr/libexec/PlistBuddy -c "Add $key:SupportedArchitectures:0 string $architecture" "$plist"
echo "Prepared macOS XCFramework and dSYM for $architecture"
