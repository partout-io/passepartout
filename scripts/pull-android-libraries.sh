#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
if [ -z $ANDROID_NDK_ROOT ]; then
    echo "Android NDK not found (missing \$ANDROID_NDK_ROOT)"
    exit 1
fi
if [ "$1" == "1" ]; then
    cfg_release="-config Release"
fi
passepartout_sha1=`git rev-parse --short HEAD`
cmake_bin_path="bin/android-aarch64"
cpp_path=`realpath app-android/app/src/main/cpp`
headers_path="$cpp_path/src"
swift_version="6_2"

set -e
rm -f $headers_path/passepartout.h
rm -f $headers_path/partout.h
rm -rf $cpp_path/libs/passepartout-*
rm -rf $cpp_path/libs/swift-*

libs_path="$cpp_path/libs/passepartout-${passepartout_sha1}/arm64-v8a"
mkdir -p $libs_path
cp $cmake_bin_path/passepartout.h $headers_path
cp $cmake_bin_path/libpassepartout_shared.so $libs_path
cp $cmake_bin_path/partout/partout.h $headers_path
cp $cmake_bin_path/partout/libpartout.so $libs_path
cp $cmake_bin_path/openssl/lib/lib*.so $libs_path
cp $cmake_bin_path/wg-go/lib/libwg-go.so $libs_path
sed -E -i '' "s/set\(PASSEPARTOUT_SHA1 ([0-9a-f]+)\)/set(PASSEPARTOUT_SHA1 ${passepartout_sha1})/" $cpp_path/CMakeLists.txt

# Pull Swift runtime
runtime_path="$cpp_path/libs/swift-${swift_version}/arm64-v8a"
mkdir -p $runtime_path
cp $ANDROID_NDK_SYSROOT/usr/lib/aarch64-linux-android/libc++_shared.so $runtime_path
pushd $SWIFT_ANDROID_RUNTIME
cp \
    libBlocksRuntime.so \
    libdispatch.so \
    libswift_math.so \
    libswift_Builtin_float.so \
    libswift_Concurrency.so \
    libswift_Differentiation.so \
    libswift_RegexParser.so \
    libswift_StringProcessing.so \
    libswift_Volatile.so \
    libswiftAndroid.so \
    libswiftCore.so \
    libswiftDispatch.so \
    libswiftRegexBuilder.so \
    libswiftSwiftOnoneSupport.so \
    libswiftSynchronization.so \
    libFoundation.so \
    libFoundationEssentials.so \
    libFoundationInternationalization.so \
    libFoundationNetworking.so \
    lib_FoundationICU.so \
    $runtime_path
popd
