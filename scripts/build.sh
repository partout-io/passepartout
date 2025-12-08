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
if [ ! -d $build_dir ]; then
    mkdir $build_dir
fi
mkdir -p bin
pushd $build_dir
rm -f *.txt

if [ "$android_flag" == "-android" ]; then
    PATH=$ANDROID_NDK_TOOLCHAIN:$PATH
    cmake -G Ninja -DCMAKE_BUILD_TYPE=$build_type -DCMAKE_TOOLCHAIN_FILE=submodules/partout/android.toolchain.cmake ..
    cmake --build .
    popd
    $cwd/pull-android-libraries.sh
else
    cmake -G Ninja -DCMAKE_BUILD_TYPE=$build_type -DBUILD_APP=ON ..
    cmake --build .
    popd
fi
