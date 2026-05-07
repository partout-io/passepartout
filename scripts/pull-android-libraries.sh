#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
source $cwd/env-android.sh
if [ -z $ANDROID_NDK_HOME ]; then
    echo "Android NDK not found (missing \$ANDROID_NDK_HOME)"
    exit 1
fi
cmake_bin_path="bin/android-$SWIFT_ANDROID_ARCH/dist"
cpp_path=`realpath app-android/app/src/main/cpp`
headers_path="$cpp_path/src"

set -e

# Rebuild library
rm -f $headers_path/passepartout.h
rm -rf $cpp_path/libs/passepartout-*
rm -rf $cpp_path/libs/swift-*

# Copy to JNI folder
libs_path="$cpp_path/libs/$ANDROID_ABI"
mkdir -p $libs_path
cp -f $cmake_bin_path/passepartout.h $headers_path
cp -f $cmake_bin_path/libpassepartout.so $libs_path
cp -f $cmake_bin_path/libssl.so $libs_path
cp -f $cmake_bin_path/libcrypto.so $libs_path
cp -f $cmake_bin_path/libwg-go.so $libs_path
# Pull C++ runtime (Swift runtime linked statically)
cp -f ${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/*/sysroot/usr/lib/${SWIFT_ANDROID_ARCH}-linux-android/libc++_shared.so $libs_path

# Generate ABI entities
scripts/gen-abi-kotlin.sh
