#!/bin/bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
app_dir=$(cd "$script_dir/.." && pwd -P)

usage() {
    cat <<'EOF'
Usage: ci/package.sh <target> <output-directory> [architecture]

Targets:
  appstore-ios       Export Passepartout.ipa for App Store Connect
  appstore-macos     Export Passepartout.pkg for App Store Connect
  appstore-tvos      Export Passepartout.ipa for App Store Connect
  dmg                Export, notarize, and sign a standalone macOS DMG

The dmg target requires an architecture (arm64 or x86_64) and these variables:
  APPLE_ID
  APPLE_ID_PASSWORD
  GPG_FINGERPRINT
  GPG_PASSPHRASE

The signing certificates, provisioning profiles, and GPG key must already be
installed. PartoutNative.xcframework must also have been prepared before this
script runs.
EOF
}

fail() {
    echo "error: $*" >&2
    exit 1
}

require_file() {
    [[ -f $1 ]] || fail "Expected package was not produced: $1"
}

stage_file() {
    local source=$1
    local destination=$2

    require_file "$source"
    cp -f "$source" "$output_dir/$destination"
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage
    exit 0
fi

[[ $# -le 3 ]] || fail "Too many arguments"

target=${1:-}
output_dir=${2:-}
architecture=${3:-}

if [[ -z $target || -z $output_dir ]]; then
    usage >&2
    exit 1
fi

if [[ $output_dir != /* ]]; then
    output_dir="$PWD/$output_dir"
fi
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd -P)

[[ $(uname -s) == Darwin ]] || fail "Apple packages must be built on macOS"
[[ -d "$app_dir/PartoutNative.xcframework" ]] || \
    fail "Missing app-apple/PartoutNative.xcframework"

cd "$app_dir"

case $target in
    appstore-ios)
        [[ -z $architecture ]] || fail "$target does not accept an architecture"
        "$script_dir/xcode-archive.sh" iOS
        "$script_dir/xcode-export.sh" iOS
        stage_file "dist/iOS/Passepartout.ipa" "Passepartout.ipa"
        ;;
    appstore-macos)
        [[ -z $architecture ]] || fail "$target does not accept an architecture"
        "$script_dir/xcode-archive.sh" macOS
        "$script_dir/xcode-export.sh" macOS
        stage_file "dist/macOS/Passepartout.pkg" "Passepartout.pkg"
        ;;
    appstore-tvos)
        [[ -z $architecture ]] || fail "$target does not accept an architecture"
        "$script_dir/xcode-archive.sh" tvOS
        "$script_dir/xcode-export.sh" tvOS
        stage_file "dist/tvOS/Passepartout.ipa" "Passepartout.ipa"
        ;;
    dmg)
        case $architecture in
            arm64|x86_64)
                ;;
            *)
                fail "The dmg target requires architecture arm64 or x86_64"
                ;;
        esac

        required_variables=(
            APPLE_ID
            APPLE_ID_PASSWORD
            GPG_FINGERPRINT
            GPG_PASSPHRASE
        )
        for variable in "${required_variables[@]}"; do
            [[ -n ${!variable:-} ]] || fail "Missing $variable"
        done

        "$script_dir/xcode-archive.sh" macOS 1 "$architecture"
        "$script_dir/xcode-export.sh" macOS 1
        "$script_dir/dmg-generate.sh" "$architecture"
        "$script_dir/dmg-notarize.sh" \
            "$architecture" "$APPLE_ID" "$APPLE_ID_PASSWORD"
        "$script_dir/dmg-sign.sh" \
            "$architecture" "$GPG_FINGERPRINT" "$GPG_PASSPHRASE"

        stage_file "Passepartout.$architecture.dmg" \
            "Passepartout.$architecture.dmg"
        stage_file "Passepartout.$architecture.dmg.asc" \
            "Passepartout.$architecture.dmg.asc"
        ;;
    *)
        usage >&2
        fail "Unknown target: $target"
        ;;
esac

echo "Package ready in $output_dir"
