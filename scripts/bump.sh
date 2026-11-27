#!/bin/bash
pushd "$(dirname "$0")/.." >/dev/null || exit 1

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

apple_xcconfig_path="Passepartout/Config.xcconfig"
android_gradle_path="app/build.gradle.kts"
edit_changelog() {
    local changelog_path="$1"
    local log_path="$changelog_path.tmp"
    local editor_exit
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
    mv "$log_path" "$changelog_path"
}

cross_version=$(cat "app-cross/version.txt")
cross_build=$(cat "app-cross/build.txt")
if [[ ! "$cross_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid Cross version in app-cross/version.txt"
    exit 1
fi
if [[ ! "$cross_build" =~ ^[1-9][0-9]*$ ]]; then
    echo "Invalid Cross build in app-cross/build.txt"
    exit 1
fi
if [[ -n "$opt_version" && ! "$opt_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Version must contain three numeric components"
    exit 1
fi

if [[ -z "$opt_build" ]]; then
    apple_build=`app-apple/ci/xcconfig-get.sh "app-apple/$apple_xcconfig_path" CURRENT_PROJECT_VERSION`
    android_build=`sed -n -E "s/^[[:space:]]*versionCode = ([0-9]+)[[:space:]]*$/\1/p" "app-android/$android_gradle_path"`
    if [[ -z "$android_build" ]]; then
        echo "Android versionCode not found in app-android/$android_gradle_path"
        exit 1
    fi
    current_build="$apple_build"
    if [[ "$android_build" -gt "$current_build" ]]; then
        current_build="$android_build"
    fi
    if [[ "$cross_build" -gt "$current_build" ]]; then
        current_build="$cross_build"
    fi
    opt_build=$((current_build + 1))
fi

if [[ ! "$opt_build" =~ ^[1-9][0-9]*$ ]] || [[ ${#opt_build} -gt 10 ]] || [[ "$opt_build" -gt 2147483647 ]]; then
    echo "Build must be a positive 32-bit integer"
    exit 1
fi

if [[ -n $opt_dry_run ]]; then
    echo "version = $opt_version"
    echo "build   = $opt_build"
    echo "since   = $opt_since"
    echo "no_log  = $opt_no_log"
    echo "no_tag  = $opt_no_tag"
    popd >/dev/null
    exit 0
fi

if [[ $opt_no_log != "1" ]]; then
    echo "Generate CHANGELOG..."
    if [[ -z "$opt_since" ]]; then
        opt_since=`git describe --abbrev=0 --tags`
    fi
    git_range="$opt_since..HEAD"
    log=$(git log $git_range --pretty="* %s" --date=short)
    edit_changelog "app-apple/CHANGELOG.txt"

    for app in Android Cross; do
        app_path="app-$(echo "$app" | tr '[:upper:]' '[:lower:]')"
        read -r -p "Reuse Apple CHANGELOG for $app? y/N " reuse_changelog
        case "$reuse_changelog" in
            y|Y)
                cp "app-apple/CHANGELOG.txt" "$app_path/CHANGELOG.txt"
                ;;
            *)
                edit_changelog "$app_path/CHANGELOG.txt"
                ;;
        esac
    done
fi

# Apple

pushd "app-apple" >/dev/null

echo "Set Apple build number to $opt_build..."
ci/xcconfig-set.sh "$apple_xcconfig_path" CURRENT_PROJECT_VERSION "$opt_build"
if [[ -n "$opt_version" ]]; then
    echo "Set Apple version number to $opt_version..."
    ci/xcconfig-set.sh "$apple_xcconfig_path" MARKETING_VERSION "$opt_version"
fi
git add "$apple_xcconfig_path"

popd >/dev/null

# Android

pushd "app-android" >/dev/null

echo "Set Android build number to $opt_build..."
ci/gradle-set.sh "$android_gradle_path" versionCode "$opt_build"
if [[ -n "$opt_version" ]]; then
    echo "Set Android version number to $opt_version..."
    ci/gradle-set.sh "$android_gradle_path" versionName "$opt_version"
fi
git add "$android_gradle_path"

popd >/dev/null

# Cross

pushd "app-cross" >/dev/null

cross_version="${opt_version:-$cross_version}"
echo "Set Cross version to $cross_version ($opt_build)..."
printf '%s\n' "$cross_version" > "version.txt"
printf '%s\n' "$opt_build" > "build.txt"
git add "version.txt" "build.txt"

popd >/dev/null

if [[ $opt_no_log != "1" ]]; then
    echo "Copy CHANGELOG to release notes..."
    scripts/copy-release-notes.sh
fi

echo "Commit changes to repository..."
git add \
    "app-apple/fastlane/metadata" \
    "app-android/app/src/main/play" \
    "app-apple/CHANGELOG.txt" \
    "app-android/CHANGELOG.txt" \
    "app-cross/CHANGELOG.txt"

git commit -m "Bump version"

if [[ -z "$opt_no_tag" ]]; then
    tag="builds/$opt_build"
    echo "Tag commit as $tag..."
    git tag -as "$tag" -m "$tag"
fi

popd >/dev/null

echo "Done!"
