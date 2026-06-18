#!/bin/bash
if [[ -z "$1" ]]; then
    echo "Path to Gradle file required"
    exit 1
fi
if [[ -z "$2" ]]; then
    echo "Setting key required"
    exit 1
fi
if [[ -z "$3" ]]; then
    echo "Setting value required"
    exit 1
fi
gradle="$1"
setting_key="$2"
setting_value="$3"
if grep -Eq "^[[:space:]]*${setting_key}[[:space:]]*=[[:space:]]*\"" "$gradle"; then
    sed -i "" -E "s|^([[:space:]]*)${setting_key}[[:space:]]*=.*$|\1${setting_key} = \"${setting_value}\"|" "$gradle"
else
    sed -i "" -E "s|^([[:space:]]*)${setting_key}[[:space:]]*=.*$|\1${setting_key} = ${setting_value}|" "$gradle"
fi
