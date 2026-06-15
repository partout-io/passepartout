#!/bin/bash
set -e
if [ ! -d build ]; then mkdir build; fi
pushd build
cmake -G Ninja \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-28 \
    -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
    ..
cmake --build .
popd
