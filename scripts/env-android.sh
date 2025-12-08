#!/bin/bash
# ANDROID_NDK_ROOT=
export SWIFT_SDK=~/.swiftpm/swift-sdks/swift-6.2-RELEASE-android-0.1.artifactbundle
export SWIFT_RESOURCE_DIR=$SWIFT_SDK/swift-android/swift-resources/usr/lib/swift_static-aarch64
export ANDROID_NDK_TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin
export ANDROID_NDK_SYSROOT=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/sysroot
export ANDROID_NDK_API=28
export ANDROID_NDK_ARCH=aarch64
