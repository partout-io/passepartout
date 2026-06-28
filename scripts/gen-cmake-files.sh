#!/bin/bash
LC_ALL=C
filelist=files.cmake
pushd app-cross
cat >${filelist} <<EOF
set(APP_SOURCES
$(find app -name "*.cc" | sort)
)
set(TUNNEL_SOURCES
$(find tunnel -name "*.c" | sort)
)
EOF
popd
