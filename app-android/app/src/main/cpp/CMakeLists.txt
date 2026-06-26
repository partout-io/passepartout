# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.28)
project(Passepartout LANGUAGES C)
set(CMAKE_C_FLAGS "-W -Wall -Werror -pedantic")

# Define wrapper
add_library(passepartout_wrapper SHARED "")

# Include Swift/CMake helpers
set(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../..")
include("${PROJECT_ROOT}/partout/cmake/swift/swift-macros.cmake")

# Set up Partout
set(PARTOUT_ROOT ${PROJECT_ROOT}/partout)
set(PARTOUT_OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(PARTOUT_LIBRARY ${PARTOUT_OUTPUT}/partout/libpartout.so)
set(PARTOUT_VENDOR_LIBRARIES
    ${PARTOUT_OUTPUT}/openssl/lib/libcrypto.so
    ${PARTOUT_OUTPUT}/openssl/lib/libssl.so
    ${PARTOUT_OUTPUT}/wg-go/lib/libwg-go.so
)
set(PARTOUT_LIBRARIES
    ${PARTOUT_LIBRARY}
    ${PARTOUT_VENDOR_LIBRARIES}
)

# Add the external Swift library
add_swift_library(partout ${PARTOUT_ROOT}
    BUILD_BYPRODUCTS ${PARTOUT_LIBRARIES}
    CMAKE_ARGS
        -DPP_BUILD_OUTPUT=${PARTOUT_OUTPUT}
        -DPP_BUILD_LIBRARY=ON
        -DPP_BUILD_USE_OPENSSL=ON
        -DPP_BUILD_USE_OPENVPN=ON
        -DPP_BUILD_USE_WIREGUARD=ON
)

# Merge with wrapper
target_link_libraries(passepartout_wrapper PRIVATE partout)
add_custom_command(TARGET passepartout_wrapper POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${PARTOUT_LIBRARIES}
        "$<TARGET_FILE_DIR:passepartout_wrapper>"
)

# Add wrapper glue
target_sources(passepartout_wrapper PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/wrapper.c
        ${CMAKE_CURRENT_SOURCE_DIR}/src/helpers.c
)
target_include_directories(passepartout_wrapper PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)
