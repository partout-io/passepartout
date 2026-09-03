#!/bin/bash
LC_ALL=C
script_dir="$(cd "$(dirname "$0")" && pwd)"
app_cross_dir="$(cd "$script_dir/.." && pwd)"
filelist=files.cmake
pushd "$app_cross_dir"
cat >${filelist} <<EOF
set(APP_SOURCES
$(find app -name "*.cc" | sort)
)
set(TUNNEL_SOURCES
$(find tunnel -name "*.c" | sort)
)
EOF
popd
