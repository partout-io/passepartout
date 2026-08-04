#!/bin/bash

set -euo pipefail

: "${BUILD_DIR:?Select a target under 'Provide build settings from'}"
: "${SRCROOT:?Missing SRCROOT}"

case "$BUILD_DIR" in
    */Build/*) ;;
    *) echo "Unexpected BUILD_DIR: $BUILD_DIR" >&2; exit 1 ;;
esac

partout_dir="$SRCROOT/../partout"
derived_data_dir="${BUILD_DIR%/Build/*}"
artifacts_dir="$derived_data_dir/SourcePackages/artifacts"

"$partout_dir/zig/scripts/build-xcframework.sh" \
    "$SRCROOT/PartoutNative.xcframework" \
    "$artifacts_dir" \
    "$@"
