#!/bin/bash
cwd=`dirname $0`
if [[ -z "$1" ]]; then
    echo "Device required"
    exit 1
fi
device=$1
cmd_compose="$cwd/compose.sh"
fastlane_screenshots_root="$cwd/../fastlane/screenshots"

case $device in

  "iphone")
    nums=("01 02 03 04 05")
    template="main"
    width=1242
    height=2688
    fastlane="iOS"
    ;;

  "ipad")
    nums=("01 02 03 04 05")
    template="main"
    width=2048
    height=2732
    fastlane="iOS"
    ;;

  "mac")
    nums=("01 02 03 04 05")
    template="main"
    width=2880
    height=1800
    fastlane="macOS"
    ;;

  "appletv")
    nums=("01 02 03")
    template="tv"
    width=3840
    height=2160
    fastlane="tvOS"
    ;;

  *)
    echo "Unknown device: $device"
    exit 1
    ;;
esac

for num in $nums; do
    $cmd_compose $template $device $num $width $height "$fastlane_screenshots_root/$fastlane/en-US"
done
