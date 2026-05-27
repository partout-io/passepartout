#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
set -e
build_dir=.cmake
bin_dir=bin

root_dir="$(dirname "$0")"/..
pushd $root_dir

positional_args=()
cmake_opts=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -gen)
            gen_build=1
            shift
            ;;
        -config)
            build_type=$2
            shift
            shift
            ;;
        -app)
            build_app=1
            shift
            ;;
    esac
done
set -- "${positional_args[@]}"

if [[ -z $build_type ]]; then
    build_type=Debug
fi
cmake_opts+=("-DCMAKE_BUILD_TYPE=$build_type")

if [[ $(uname -s) == "Linux" ]]; then
    source $cwd/env-linux.sh
    if [[ $gen_build == 1 ]]; then
        cmake_opts+=("-DCMAKE_TOOLCHAIN_FILE=$partout_toolchains_path/linux.toolchain.cmake")
    fi
fi

if [[ $build_app == 1 ]]; then
    cmake_opts+=("-DBUILD_APP=ON")
fi

if [[ ! -d $build_dir ]]; then
    mkdir $build_dir
fi
if [[ ! -d $bin_dir ]]; then
    mkdir $bin_dir
fi
if [[ $gen_build == 1 ]]; then
    scripts/gen-cmake-files.sh
    pushd $build_dir
    cmake -G Ninja "${cmake_opts[@]}" ..
else
    pushd $build_dir
fi
cmake --build .
popd

popd
