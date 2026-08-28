#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
set -e
root_dir="$(cd "$(dirname "$0")"/.. && pwd)"
build_dir="$root_dir/.cmake"
bin_dir="bin"
prebuilts_version=$(tr -d '\r\n' < "$root_dir/prebuilts-version.txt")

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
            if [[ -z ${2:-} || $2 == -* ]]; then
                echo "-config requires a value"
                exit 1
            fi
            build_type=$2
            shift
            shift
            ;;
        -app)
            build_app=1
            shift
            ;;
        -prebuilts)
            if [[ -z ${2:-} || $2 == -* ]]; then
                echo "-prebuilts requires a version"
                exit 1
            fi
            prebuilts_version=$2
            shift
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

if [[ ! $prebuilts_version =~ ^[0-9A-Za-z][0-9A-Za-z._+-]*$ ]]; then
    echo "Invalid prebuilts version: $prebuilts_version"
    exit 1
fi

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

if [[ $build_app == 1 ]]; then
    cmake_opts+=("-DBUILD_APP=ON")
else
    cmake_opts+=("-DBUILD_APP=OFF")
fi
cmake_opts+=("-DPASSEPARTOUT_PREBUILTS_VERSION=$prebuilts_version")

if [[ ! -d "$build_dir" ]]; then
    mkdir "$build_dir"
fi
if [[ ! -d "$bin_dir" ]]; then
    mkdir "$bin_dir"
fi
if [[ $gen_build == 1 ]]; then
    scripts/gen-cmake-files.sh
    pushd "$build_dir"
    cmake -G Ninja "${cmake_opts[@]}" "$root_dir/app-cross"
else
    pushd "$build_dir"
fi
cmake --build . --config "$build_type"
cmake --install . --config "$build_type" --prefix "$dist_dir" --strip
popd

popd
