#!/bin/bash
if [ -z $ANDROID_NDK_ROOT ]; then
    echo "Android NDK not found"
    exit 1
fi

RUNTIME_ROOT=~/.swiftpm/swift-sdks/swift-6.2-RELEASE-android-0.1.artifactbundle/swift-android/swift-resources/usr/lib/swift-aarch64/android

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
rm -rf $cpp_path/libs/swift*

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
    ${RUNTIME_ROOT}/libBlocksRuntime.so \
    ${RUNTIME_ROOT}/libdispatch.so \
    ${RUNTIME_ROOT}/libswift_math.so \
    ${RUNTIME_ROOT}/libswift_Builtin_float.so \
    ${RUNTIME_ROOT}/libswift_Concurrency.so \
    ${RUNTIME_ROOT}/libswift_Differentiation.so \
    ${RUNTIME_ROOT}/libswift_RegexParser.so \
    ${RUNTIME_ROOT}/libswift_StringProcessing.so \
    ${RUNTIME_ROOT}/libswift_Volatile.so \
    ${RUNTIME_ROOT}/libswiftAndroid.so \
    ${RUNTIME_ROOT}/libswiftCore.so \
    ${RUNTIME_ROOT}/libswiftDispatch.so \
    ${RUNTIME_ROOT}/libswiftRegexBuilder.so \
    ${RUNTIME_ROOT}/libswiftSwiftOnoneSupport.so \
    ${RUNTIME_ROOT}/libswiftSynchronization.so \
    ${RUNTIME_ROOT}/libFoundation.so \
    ${RUNTIME_ROOT}/libFoundationEssentials.so \
    ${RUNTIME_ROOT}/libFoundationInternationalization.so \
    ${RUNTIME_ROOT}/lib_FoundationICU.so \
    $runtime_path
