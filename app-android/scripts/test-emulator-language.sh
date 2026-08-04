#!/bin/sh
package=com.algoritmico.passepartout
lang=$1
set -e
if [[ -n "$2" ]]; then
    device_arg="-s $2"
else
    device_arg=""
fi
adb $device_arg shell cmd locale set-app-locales $package --locales $1
adb $device_arg shell am force-stop $package
adb $device_arg shell monkey -p $package 1
