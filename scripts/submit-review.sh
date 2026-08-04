#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

if [[ -n "$1" ]]; then
    platforms="$1"
fi
if [[ -z "$platforms" ]]; then
    echo "No platforms provided"
    exit 1
fi
export DELIVER_APP_VERSION=`app-apple/ci/version-number.sh`
export DELIVER_BUILD_NUMBER=`app-apple/ci/build-number.sh`
export DELIVER_FORCE=true
for platform in $platforms; do
    if ! bundle exec fastlane --env secret,$platform asc_review; then
        exit 1
    fi
done
