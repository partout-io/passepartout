#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
set -e
root_dir="$(cd "$(dirname "$0")"/.. && pwd)"
build_dir="$root_dir/.cmake"
bin_dir="bin"

pushd "$root_dir"

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
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            positional_args+=("$1")
            shift
            ;;
    esac
done
set -- "${positional_args[@]}"

if [[ -z $build_type ]]; then
    build_type=Debug
fi
platform_name=$(uname -s | tr '[:upper:]' '[:lower:]')
arch_name=$(uname -m | tr '[:upper:]' '[:lower:]')
output_dir="$root_dir/$bin_dir/$platform_name-$arch_name"
dist_dir="$root_dir/dist"

cmake_opts+=("-DCMAKE_BUILD_TYPE=$build_type")
cmake_opts+=("-DOUTPUT_DIR=$output_dir")
cmake_opts+=("-DCMAKE_INSTALL_LIBDIR=.")
cmake_opts+=("-DCMAKE_INSTALL_BINDIR=.")

if [[ $(uname -s) == "Linux" ]]; then
    if [[ $gen_build == 1 ]]; then
        cmake_opts+=("-DSWIFT_VERSION=$cmake_swift_version")
        cmake_opts+=("-DCMAKE_TOOLCHAIN_FILE=$cmake_toolchains_path/swift-linux.toolchain.cmake")
    fi
fi

if [[ $build_app == 1 ]]; then
    cmake_opts+=("-DBUILD_APP=ON")
fi

if [[ ! -d "$build_dir" ]]; then
    mkdir "$build_dir"
fi
if [[ ! -d "$bin_dir" ]]; then
    mkdir "$bin_dir"
fi
if [[ $gen_build == 1 ]]; then
    scripts/gen-cmake-files.sh
    pushd "$build_dir"
    cmake -G Ninja "${cmake_opts[@]}" ..
else
    pushd "$build_dir"
fi
cmake --build . --config "$build_type"
cmake --install . --config "$build_type" --prefix "$dist_dir" --strip
popd

popd
