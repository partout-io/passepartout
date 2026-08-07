#!/bin/bash

# CI uses the remote PartoutNative artifact declared in Package.swift.
if [[ ${CI:-} == true ]]; then
    exit 0
fi

set -euo pipefail

fail() {
    echo "prebuild-zig-xcframework.sh: $*" >&2
    exit 1
}

: "${BUILD_DIR:?Select a target under 'Provide build settings from'}"
: "${SRCROOT:?Missing SRCROOT}"

case "$BUILD_DIR" in
    */Build/*) ;;
    *) echo "Unexpected BUILD_DIR: $BUILD_DIR" >&2; exit 1 ;;
esac

for tool in curl ditto swift; do
    command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
done

partout_dir="$SRCROOT/../partout"
artifacts_dir="$SRCROOT/artifacts"
prebuilts_url=https://github.com/partout-io/prebuilts/releases/latest

mkdir -p "$artifacts_dir"
artifacts_dir=$(cd "$artifacts_dir" && pwd -P)

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/partout-prebuilts.XXXXXX")
trap 'rm -rf "$temp_dir"' EXIT

compute_checksum() {
    swift package compute-checksum "$1"
}

for vendor in openssl mbedtls wg-go; do
    archive="$vendor.xcframework.zip"
    release_checksum="$archive.checksum"
    curl -fsSL --retry 3 \
        --output "$temp_dir/$release_checksum" \
        "$prebuilts_url/download/$release_checksum"
    expected_checksum=$(<"$temp_dir/$release_checksum")
    [[ $expected_checksum =~ ^[[:xdigit:]]{64}$ ]] ||
        fail "invalid checksum in $release_checksum"

    archive_path="$artifacts_dir/$archive"
    actual_checksum=
    if [[ -f $archive_path ]]; then
        actual_checksum=$(compute_checksum "$archive_path")
    fi

    if [[ $actual_checksum == "$expected_checksum" ]]; then
        echo "Using cached $archive"
    else
        echo "Downloading $archive from the latest prebuilts release"
        curl -fsSL --retry 3 \
            --output "$temp_dir/$archive" \
            "$prebuilts_url/download/$archive"
        actual_checksum=$(compute_checksum "$temp_dir/$archive")
        [[ $actual_checksum == "$expected_checksum" ]] ||
            fail "checksum mismatch for $archive"
        mv "$temp_dir/$archive" "$archive_path"
    fi
    mv "$temp_dir/$release_checksum" "$artifacts_dir/$release_checksum"

    framework="$artifacts_dir/$vendor.xcframework"
    checksum_marker="$artifacts_dir/.$vendor.xcframework.checksum"
    extracted_checksum=
    if [[ -f $checksum_marker ]]; then
        extracted_checksum=$(<"$checksum_marker")
    fi

    if [[ -d $framework && $extracted_checksum == "$expected_checksum" ]]; then
        echo "Using extracted $vendor.xcframework"
        continue
    fi

    echo "Extracting $archive"
    extract_dir="$temp_dir/$vendor"
    mkdir -p "$extract_dir"
    ditto -x -k "$archive_path" "$extract_dir"
    [[ -d "$extract_dir/$vendor.xcframework" ]] ||
        fail "missing $vendor.xcframework in $archive"
    rm -rf "$framework"
    mv "$extract_dir/$vendor.xcframework" "$framework"
    printf '%s\n' "$expected_checksum" > "$checksum_marker"
done

"$partout_dir/scripts/build-xcframework.sh" \
    "$SRCROOT/PartoutNative.xcframework" \
    "$artifacts_dir" \
    "$@" \
    "--monolith"
