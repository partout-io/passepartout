#!/bin/bash
cwd=`dirname $0`
device="$1"
xcscheme="PassepartoutUITests"
results_root="$cwd/results"
results_path="$results_root/$device"
screenshots_path="$cwd/html/$device"

mkdir -p "$results_root"
mkdir -p "$screenshots_path"

case $device in

  "iphone")
    xcplan="MainScreenshots"
    xcdestination="name=iPhone 16 Pro Max"
    ;;

  "ipad")
    xcplan="MainScreenshots"
    xcdestination="name=iPad (10th generation)"
    ;;

  "mac")
    xcplan="MainScreenshots"
    xcdestination="platform=macOS,arch=arm64"
    ;;

  "appletv")
    xcplan="TVScreenshots"
    xcdestination="name=Apple TV 4K (3rd generation)"
    ;;

  *)
    echo "Unknown device: $device"
    exit 1
    ;;
esac

# 1. run the tests
rm -rf "$results_path"
xcodebuild -scheme "$xcscheme" -testPlan "$xcplan" -destination "$xcdestination" -resultBundlePath "$results_path" test

# 2. parse the screenshots
xcparse screenshots "$results_path" "$screenshots_path"

# 3. drop the filename suffix
cd "$screenshots_path"
for file in 0[1-9]_*.png; do
    if [[ -e "$file" ]]; then
        new_name="${file%%_*}.png"
        mv "$file" "$new_name"
    fi
done
