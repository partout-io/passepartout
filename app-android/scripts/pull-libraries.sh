#!/bin/bash
is_release=$1  # 1 for Release
partout_path="../submodules/partout"
partout_vendors_path="../submodules/partout/.bin/android-arm64"
cpp_path="app/src/main/cpp"
headers_path="$cpp_path/src"

if [ "$is_release" == 1 ]; then
    partout_so_path="${partout_path}/.build/release"
else
    partout_so_path="${partout_path}/.build/debug"
fi

set -e
pushd $partout_path
partout_sha1=`git rev-parse --short HEAD`
scripts/build-android.sh "$is_release"
popd

rm -f $headers_path/partout.h
rm -rf $cpp_path/libs/partout-*

libs_path="$cpp_path/libs/partout-${partout_sha1}/arm64-v8a"
mkdir -p $libs_path
cp $partout_path/Sources/PartoutABI_C/include/partout.h $headers_path
cp $partout_so_path/libpartout.so $libs_path
cp $partout_vendors_path/wg-go/lib/libwg-go.so $libs_path
sed -E -i '' "s/set\(PARTOUT_SHA1 ([0-9a-f]+)\)/set(PARTOUT_SHA1 ${partout_sha1})/" $cpp_path/CMakeLists.txt
