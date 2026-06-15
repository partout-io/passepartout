#!/bin/bash
LC_ALL=C
libpassepartout=passepartout_shared.cmake
passepartout=passepartout.cmake

pushd app-shared
cat >${libpassepartout} <<EOF
set(PSP_SOURCES
$(find Sources -name "*.swift" | sort)
)
set(PSP_C_SOURCES
$(find Sources -name "*.c" | sort)
)
EOF
popd

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
