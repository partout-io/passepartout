#!/bin/bash
platforms="iOS macOS tvOS"
changelog="CHANGELOG.txt"
metadata_root="fastlane/metadata"
metadata_path="default/release_notes.txt"
translations_input_path="l10n"
translations_output_path="app-shared/Sources/AppStrings/Resources"
build_type=Release

# Required by Swift on non-Apple
export SWIFT_SDK=~/.local/share/swiftly/toolchains/6.2.0/usr/lib/swift/linux
export SWIFT_RUNTIME=$SWIFT_SDK
# Required by Android toolchain
# ANDROID_NDK_ROOT=
export SWIFT_ANDROID_SDK=~/.swiftpm/swift-sdks/swift-6.2-RELEASE-android-0.1.artifactbundle

export ANDROID_NDK_TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin
export ANDROID_NDK_SYSROOT=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/sysroot
export ANDROID_NDK_API=28
export SWIFT_ANDROID_RESOURCE_DIR=$SWIFT_ANDROID_SDK/swift-android/swift-resources/usr/lib/swift-aarch64
export SWIFT_ANDROID_RUNTIME=$SWIFT_ANDROID_RESOURCE_DIR/android
