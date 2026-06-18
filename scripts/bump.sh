#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

positional_args=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -v)
      opt_version="$2"
      shift # past argument
      shift # past value
      ;;
    -b)
      opt_build="$2"
      shift # past argument
      shift # past value
      ;;
    -s)
      opt_since="$2"
      shift # past argument
      shift # past value
      ;;
    -nl)
      opt_no_log=1
      shift # past argument
      ;;
    -nt)
      opt_no_tag=1
      shift
      ;;
    -d)
      opt_dry_run=1
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      positional_args+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${positional_args[@]}" # restore positional parameters
set -e

cwd=`dirname $0`
apple_xcconfig_path="app-apple/Passepartout/Config.xcconfig"
android_gradle_path="app-android/app/build.gradle.kts"

if [[ -z "$opt_build" ]]; then
    apple_build=`app-apple/ci/xcconfig-get.sh "$apple_xcconfig_path" CURRENT_PROJECT_VERSION`
    android_build=`sed -n -E "s/^[[:space:]]*versionCode = ([0-9]+)[[:space:]]*$/\1/p" "$android_gradle_path"`
    if [[ -z "$android_build" ]]; then
        echo "Android versionCode not found in $android_gradle_path"
        exit 1
    fi
    current_build="$apple_build"
    if [[ "$android_build" -gt "$current_build" ]]; then
        current_build="$android_build"
    fi
    opt_build=$((current_build + 1))
fi

if [[ -n $opt_dry_run ]]; then
    echo "version = $opt_version"
    echo "build   = $opt_build"
    echo "since   = $opt_since"
    echo "no_log  = $opt_no_log"
    echo "no_tag  = $opt_no_tag"
    exit 0
fi

if [[ $opt_no_log != "1" ]]; then
    echo "Generate CHANGELOG..."
    if [[ -z "$opt_since" ]]; then
        opt_since=`git describe --abbrev=0 --tags`
    fi
    git_range="$opt_since..HEAD"
    log=$(git log $git_range --pretty="* %s" --date=short)
    log_path="$changelog.tmp"
    echo "$log" >"$log_path"

    set +e
    $EDITOR "$log_path"
    editor_exit=$?
    set -e

    echo "Editor exited with code $editor_exit"
    if [[ $editor_exit != 0 ]]; then
        echo "CHANGELOG editor cancelled"
        rm "$log_path"
        exit 1
    fi

    echo "Copy CHANGELOG..."
    mv "$log_path" "$changelog"
fi

# Apple

pushd "app-apple"

source "scripts/env.sh"
echo "Set build number to $opt_build..."
ci/xcconfig-set.sh "$xcconfig_path" CURRENT_PROJECT_VERSION "$opt_build"
if [[ -n "$opt_version" ]]; then
    echo "Set version number to $opt_version..."
    ci/xcconfig-set.sh $xcconfig_path MARKETING_VERSION "$opt_version"
fi
git add "$xcconfig_path"

popd

# Android

echo "Set Android build number to $opt_build..."
app-android/ci/gradle-set.sh "$android_gradle_path" versionCode "$opt_build"
if [[ -n "$opt_version" ]]; then
    echo "Set Android version number to $opt_version..."
    app-android/ci/gradle-set.sh "$android_gradle_path" versionName "$opt_version"
fi
git add "$android_gradle_path"

# Cross

if [[ $opt_no_log != "1" ]]; then
    echo "Copy CHANGELOG to release notes..."
    scripts/copy-release-notes.sh
fi

echo "Commit changes to repository..."
git add \
    "$metadata_root" \
    "$changelog"

git commit -m "Bump version"

if [[ -z "$opt_no_tag" ]]; then
    tag="builds/$opt_build"
    echo "Tag commit as $tag..."
    git tag -as "$tag" -m "$tag"
fi

echo "Done!"
