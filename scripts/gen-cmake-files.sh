#!/bin/bash
libpassepartout=libpassepartout.cmake
passepartout=passepartout.cmake

cd app-cross
cat >${libpassepartout} <<EOF
set(PSP_SOURCES
$(find Sources -name "*.swift")
)
set(PSP_C_SOURCES
$(find Sources -name "*.c")
)
EOF

cd passepartout
cat >${passepartout} <<EOF
set(APP_SOURCES
$(find app -name "*.cc")
)
set(TUNNEL_SOURCES
$(find tunnel -name "*.c")
)
EOF
