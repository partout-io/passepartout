#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
source $cwd/env-android.sh
if [ -z $ANDROID_NDK_ROOT ]; then
    echo "Android NDK not found (missing \$ANDROID_NDK_ROOT)"
    exit 1
fi
passepartout_sha1=`git rev-parse --short HEAD`
cmake_bin_path="bin/android-aarch64"
cpp_path=`realpath app-android/app/src/main/cpp`
headers_path="$cpp_path/src"
swift_version="6_2"

set -e
rm -f $headers_path/passepartout.h
rm -rf $cpp_path/libs/passepartout-*
rm -rf $cpp_path/libs/swift-*

libs_path="$cpp_path/libs/passepartout-${passepartout_sha1}/arm64-v8a"
mkdir -p $libs_path
cp $cmake_bin_path/passepartout.h $headers_path
cp $cmake_bin_path/libpassepartout_shared.so $libs_path
cp $cmake_bin_path/openssl/lib/lib*.so $libs_path
cp $cmake_bin_path/wg-go/lib/lib*.so $libs_path
# Pull C++ runtime (Swift runtime linked statically)
cp $ANDROID_NDK_SYSROOT/usr/lib/aarch64-linux-android/libc++_shared.so $libs_path
sed -E -i '' "s/set\(PASSEPARTOUT_SHA1 ([0-9a-f]+)\)/set(PASSEPARTOUT_SHA1 ${passepartout_sha1})/" $cpp_path/CMakeLists.txt
