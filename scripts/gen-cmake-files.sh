#!/bin/bash
libpassepartout=libpassepartout.cmake
passepartout=passepartout.cmake

cd app-cross
echo 'set(PSP_SOURCES' >${libpassepartout}
find Sources -name "*.swift" >>${libpassepartout}
echo ')' >>${libpassepartout}
echo 'set(PSP_C_SOURCES' >>${libpassepartout}
find Sources -name "*.c" >>${libpassepartout}
echo ')' >>${libpassepartout}

cd passepartout
echo 'set(APP_SOURCES' >${passepartout}
find app -name "*.c" >>${passepartout}
find app -name "*.cc" >>${passepartout}
echo ')' >>${passepartout}
echo 'set(TUNNEL_SOURCES' >>${passepartout}
find tunnel -name "*.c" >>${passepartout}
echo ')' >>${passepartout}
