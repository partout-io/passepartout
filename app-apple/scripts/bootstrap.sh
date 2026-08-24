#!/bin/bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
app_dir=$(cd "$script_dir/.." && pwd -P)
archive="$script_dir/PartoutNative.xcframework.zip"
xcframework="$app_dir/PartoutNative.xcframework"

if [[ -d $xcframework ]]; then
    exit 0
fi

ditto -x -k "$archive" "$app_dir"
[[ -f $xcframework/Info.plist ]] || {
    echo "bootstrap.sh: failed to extract PartoutNative.xcframework" >&2
    exit 1
}
