#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
if [ -z $ANDROID_NDK_ROOT ]; then
    echo "Android NDK not found (missing \$ANDROID_NDK_ROOT)"
    exit 1
fi

is_release=$1  # 1 for Release
partout_path="../submodules/partout"
partout_vendors_path="../submodules/partout/.bin/android-arm64"
cpp_path="app/src/main/cpp"
headers_path="$cpp_path/src"
swift_version="6_2"

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
rm -rf $cpp_path/libs/swift-*

libs_path="$cpp_path/libs/partout-${partout_sha1}/arm64-v8a"
mkdir -p $libs_path
cp $partout_path/Sources/PartoutABI_C/include/partout.h $headers_path
cp $partout_so_path/libpartout.so $libs_path
cp $partout_vendors_path/wg-go/lib/libwg-go.so $libs_path
sed -E -i '' "s/set\(PARTOUT_SHA1 ([0-9a-f]+)\)/set(PARTOUT_SHA1 ${partout_sha1})/" $cpp_path/CMakeLists.txt

# Pull Swift runtime
runtime_path="$cpp_path/libs/swift-${swift_version}/arm64-v8a"
mkdir -p $runtime_path
cp ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/*/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so $runtime_path
cp \
    ${sdk_runtime_root}/libBlocksRuntime.so \
    ${sdk_runtime_root}/libdispatch.so \
    ${sdk_runtime_root}/libswift_math.so \
    ${sdk_runtime_root}/libswift_Builtin_float.so \
    ${sdk_runtime_root}/libswift_Concurrency.so \
    ${sdk_runtime_root}/libswift_Differentiation.so \
    ${sdk_runtime_root}/libswift_RegexParser.so \
    ${sdk_runtime_root}/libswift_StringProcessing.so \
    ${sdk_runtime_root}/libswift_Volatile.so \
    ${sdk_runtime_root}/libswiftAndroid.so \
    ${sdk_runtime_root}/libswiftCore.so \
    ${sdk_runtime_root}/libswiftDispatch.so \
    ${sdk_runtime_root}/libswiftRegexBuilder.so \
    ${sdk_runtime_root}/libswiftSwiftOnoneSupport.so \
    ${sdk_runtime_root}/libswiftSynchronization.so \
    ${sdk_runtime_root}/libFoundation.so \
    ${sdk_runtime_root}/libFoundationEssentials.so \
    ${sdk_runtime_root}/libFoundationInternationalization.so \
    ${sdk_runtime_root}/lib_FoundationICU.so \
    $runtime_path
