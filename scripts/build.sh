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
toolchain_dir=`realpath submodules/partout/toolchains`
if [ ! -d $build_dir ]; then
    mkdir $build_dir
fi
mkdir -p bin

# To be 100% sure
rm -f bin/*/libpassepartout.*

if [ "$android_flag" == "-android" ]; then
    source $cwd/env-android.sh
    toolchain_arg="-DCMAKE_TOOLCHAIN_FILE=$toolchain_dir/android.toolchain.cmake"
    PATH=$ANDROID_NDK_TOOLCHAIN:$PATH
    pushd $build_dir
    #rm -f *.txt
    cmake -G Ninja -DCMAKE_BUILD_TYPE=$build_type $toolchain_arg ..
    cmake --build .
    popd
    $cwd/pull-android-libraries.sh
else
    if [ $(uname -s) == "Linux" ]; then
        source $cwd/env-linux.sh
        toolchain_arg="-DCMAKE_TOOLCHAIN_FILE=$toolchain_dir/linux.toolchain.cmake"
    fi
    pushd $build_dir
    #rm -f *.txt
    cmake -G Ninja -DCMAKE_BUILD_TYPE=$build_type $toolchain_arg -DBUILD_APP=ON ..
    cmake --build .
    popd
fi
