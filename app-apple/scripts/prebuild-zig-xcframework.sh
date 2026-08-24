#!/bin/bash

set -euo pipefail

[[ -z ${CI:-} ]] || exit 0

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
partout_dir=$(cd "$script_dir/../../partout" && pwd -P)
"$partout_dir/scripts/build-xcframework.sh" \
    "$script_dir/../PartoutNative.xcframework" \
    "$partout_dir/prebuilts"
