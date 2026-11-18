#!/bin/bash

set -euo pipefail

[[ -z ${CI:-} ]] || exit 0

# Partout sets deployment targets per slice; Xcode exports competing platform defaults.
unset MACOSX_DEPLOYMENT_TARGET IPHONEOS_DEPLOYMENT_TARGET TVOS_DEPLOYMENT_TARGET \
    WATCHOS_DEPLOYMENT_TARGET XROS_DEPLOYMENT_TARGET

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
root_dir=$(cd "$script_dir/../.." && pwd -P)
partout_dir="$root_dir/partout"
prebuilts_version=$(tr -d '\r\n' < "$root_dir/.prebuilts-version")
[[ $prebuilts_version =~ ^[0-9A-Za-z][0-9A-Za-z._+-]*$ ]] || {
    echo "Invalid prebuilts version: $prebuilts_version" >&2
    exit 1
}
"$partout_dir/scripts/build-xcframework.sh" \
    "$prebuilts_version" \
    --out "$script_dir/../PartoutNative.xcframework" \
    --prebuilts-out "$partout_dir/prebuilts"
