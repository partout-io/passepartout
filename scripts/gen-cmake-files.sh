#!/bin/bash
LC_ALL=C
passepartout=passepartout.cmake
pushd app-cross
cat >${passepartout} <<EOF
set(APP_SOURCES
$(find app -name "*.cc" | sort)
)
set(TUNNEL_SOURCES
$(find tunnel -name "*.c" | sort)
)
EOF
popd
