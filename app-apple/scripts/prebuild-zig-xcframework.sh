#!/bin/bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
partout_dir=$(cd "$script_dir/../../partout" && pwd -P)
grep -qFx 'nativeTarget = .local' "$partout_dir/Package.swift" || exit 0

: "${BUILD_DIR:?Select a target under 'Provide build settings from'}"
: "${SRCROOT:?Missing SRCROOT}"

case "$BUILD_DIR" in
    */Build/*) ;;
    *) echo "Unexpected BUILD_DIR: $BUILD_DIR" >&2; exit 1 ;;
esac

cd "$partout_dir" && scripts/build-xcframework.sh
