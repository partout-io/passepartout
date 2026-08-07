# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.28)
project(Passepartout LANGUAGES C)

add_library(passepartout_wrapper SHARED jvm.c)
target_compile_options(passepartout_wrapper PRIVATE -W -Wall -Werror -pedantic)
set(PREBUILTS_VERSION 0.6.0)

set(PP_BUILD_OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/bin")
set(PP_BUILD_USE_OPENVPN ON)
set(PP_BUILD_USE_WIREGUARD ON)
set(PP_BUILD_USE_OPENSSL ON)
set(PP_BUILD_USE_MBEDTLS OFF)
set(PP_BUILD_VENDOR_PREBUILT_URL "https://github.com/partout-io/prebuilts/releases/download/${PREBUILTS_VERSION}")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../../../../../partout" partout)

add_dependencies(passepartout_wrapper partout)
target_include_directories(passepartout_wrapper PRIVATE "${PP_BUILD_OUTPUT}/partout/include")
target_link_directories(passepartout_wrapper PRIVATE "${PP_BUILD_OUTPUT}/partout/lib")
target_link_libraries(passepartout_wrapper PRIVATE
    -lpartout
    android
    log
)
add_custom_command(TARGET passepartout_wrapper POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "${PP_BUILD_OUTPUT}/partout/lib/libpartout.so"
        "${PP_BUILD_OUTPUT}/wg-go/lib/libwg-go.so"
        "${PP_BUILD_OUTPUT}/openssl/lib/libcrypto.so"
        "${PP_BUILD_OUTPUT}/openssl/lib/libssl.so"
        "$<TARGET_FILE_DIR:passepartout_wrapper>"
    VERBATIM
)
