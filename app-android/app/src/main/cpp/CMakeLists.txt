# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.28)
project(Passepartout LANGUAGES C)

add_library(passepartout_wrapper SHARED jvm.c)
target_compile_options(passepartout_wrapper PRIVATE -W -Wall -Werror -pedantic)

include("${CMAKE_CURRENT_SOURCE_DIR}/../../../../../cmake/prebuilts.cmake")

set(PP_BUILD_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/bin")
set(PP_BUILD_USE_OPENVPN ON)
set(PP_BUILD_USE_WIREGUARD ON)
set(PP_BUILD_USE_OPENSSL ON)
set(PP_BUILD_USE_MBEDTLS ON)
if(NOT PP_BUILD_VENDOR_PREBUILT_URL)
    set(PP_BUILD_VENDOR_PREBUILT_URL "${PASSEPARTOUT_PREBUILTS_URL}")
endif()
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../../../../../partout" partout)

target_link_libraries(passepartout_wrapper PRIVATE
    Partout::Partout
    android
    log
)
