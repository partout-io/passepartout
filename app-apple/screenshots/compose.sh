#!/bin/bash
cwd=`dirname $0`
if [[ $# < 6 ]]; then
    echo "6 arguments required"
    exit 1
fi
cmd_chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
cmd_magick="magick"

# e.g.: <self> main iphone 01 1242 2688 "app-apple/fastlane/screenshots/iOS"

template=$1
device=$2
num=$3
width=$4
height=$5
screenshots_root="$6"

# work around Chrome bug
height_bottom_padding="100"
padded_height=$(($height + $height_bottom_padding))

tmp_screenshot_path="tmp.png"

echo "Take screenshot $num for $device..."
page_url="file://`pwd`/$cwd/html/${template}.html?classes=${device},screen-${num}"
"$cmd_chrome" --headless --disable-gpu --window-size="$width,$padded_height" --screenshot="$tmp_screenshot_path" --virtual-time-budget=10000 "$page_url"

if [[ $device = "ipad" ]]; then
    device="ipadPro129"
fi
screenshot_path="$screenshots_root/$device-$num.png"

$cmd_magick $tmp_screenshot_path -geometry 100% -crop ${width}x${height}+0+0 +repage "$screenshot_path"
rm $tmp_screenshot_path
