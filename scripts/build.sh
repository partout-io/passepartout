#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
set -e

# Use switch statement later for more flags
android_flag="$1"
if [[ -n "$android_flag" && "$android_flag" != "-android" ]]; then
    echo "Either pass -android or nothing"
    exit 1
fi

build_dir=".cmake${android_flag}"
toolchain_dir=`realpath $toolchains_path`
if [ ! -d $build_dir ]; then
    mkdir $build_dir
fi
mkdir -p bin

if [ "$android_flag" == "-android" ]; then
    if [[ ! -d $ANDROID_NDK_HOME ]]; then
        echo "\$ANDROID_NDK_HOME must point to the Android NDK"
        exit 1
    fi
    source $cwd/env-android.sh
    toolchain_arg="-DCMAKE_TOOLCHAIN_FILE=$toolchain_dir/android.toolchain.cmake"
    pushd $build_dir
    cmake -G Ninja -DCMAKE_BUILD_TYPE=$build_type $toolchain_arg ..
    cmake --build .
    popd
else
    if [ $(uname -s) == "Linux" ]; then
        source $cwd/env-linux.sh
        toolchain_arg="-DCMAKE_TOOLCHAIN_FILE=$toolchain_dir/linux.toolchain.cmake"
    fi
    pushd $build_dir
    cmake -G Ninja -DCMAKE_BUILD_TYPE=$build_type $toolchain_arg -DBUILD_APP=ON ..
    cmake --build .
    popd
fi
