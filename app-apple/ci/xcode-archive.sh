#!/bin/bash
set -e
cwd=`dirname $0`
platform=$1
developer_id=$2
arch=$3
if [[ -z $platform ]]; then
    echo "Missing platform"
    exit 1
fi
project_name="Passepartout"
scheme="Passepartout"
configuration="Release"
if [[ $developer_id == 1 ]]; then
    scheme="PassepartoutMac"
    configuration="ReleaseMac"
fi
dst="build"
if [[ -n $arch ]]; then
    arch_line="ARCHS=$arch ONLY_ACTIVE_ARCH=NO"
fi
xcodebuild archive \
    -project $project_name.xcodeproj \
    -destination "generic/platform=$platform" \
    -archivePath "$dst/$platform/$project_name.xcarchive" \
    -scheme $scheme \
    -configuration $configuration \
    $arch_line

"$cwd/xcode-assert-archive.sh" "$dst/$platform/$project_name.xcarchive" "$developer_id"
