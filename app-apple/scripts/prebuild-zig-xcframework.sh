#!/bin/bash

# CI uses the remote PartoutNative artifact declared in Package.swift.
if [[ ${CI:-} == true ]]; then
    exit 0
fi

set -euo pipefail

: "${BUILD_DIR:?Select a target under 'Provide build settings from'}"
: "${SRCROOT:?Missing SRCROOT}"

case "$BUILD_DIR" in
    */Build/*) ;;
    *) echo "Unexpected BUILD_DIR: $BUILD_DIR" >&2; exit 1 ;;
esac

partout_dir="$SRCROOT/../partout"

cd "$partout_dir" && scripts/build-xcframework.sh
