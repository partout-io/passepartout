#!/bin/bash

set -euo pipefail

[[ -z ${CI:-} ]] || exit 0

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
root_dir=$(cd "$script_dir/../.." && pwd -P)
partout_dir="$root_dir/partout"
prebuilts_version=$(tr -d '\r\n' < "$root_dir/prebuilts-version.txt")
[[ $prebuilts_version =~ ^[0-9A-Za-z][0-9A-Za-z._+-]*$ ]] || {
    echo "Invalid prebuilts version: $prebuilts_version" >&2
    exit 1
}
"$partout_dir/scripts/build-xcframework.sh" \
    "$prebuilts_version" \
    "$script_dir/../PartoutNative.xcframework" \
    "$partout_dir/prebuilts"
