#!/bin/bash
libpassepartout=libpassepartout.cmake
passepartout=passepartout.cmake

cd app-cross
cat >${libpassepartout} <<EOF
set(PSP_SOURCES
$(find Sources -name "*.swift" | sort)
)
set(PSP_C_SOURCES
$(find Sources -name "*.c" | sort)
)
EOF

cd passepartout
cat >${passepartout} <<EOF
set(APP_SOURCES
$(find app -name "*.cc" | sort)
)
set(TUNNEL_SOURCES
$(find tunnel -name "*.c" | sort)
)
EOF
