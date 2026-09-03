#!/bin/bash
cwd=`dirname $0`
source $cwd/../app-apple/scripts/env.sh
cd $cwd/..

changelog="CHANGELOG.txt"
metadata_root_apple="app-apple/fastlane/metadata"
metadata_root_android="app-android/app/src/main/play"
metadata_path_apple="default/release_notes.txt"

if [[ -n "$1" ]]; then
    platforms="$1"
fi
if [[ -z "$platforms" ]]; then
    echo "No platforms provided"
    exit 1
fi
for platform in $platforms; do
    release_notes="$metadata_root_apple/$platform/$metadata_path_apple"
    rm -f "$release_notes"
    cp "app-apple/$changelog" "$release_notes"
done

for release_notes in "$metadata_root_android"/release-notes/*/*.txt; do
    if [[ ! -f "$release_notes" ]]; then
        continue
    fi
    rm -f "$release_notes"
    cp "app-android/$changelog" "$release_notes"
done
