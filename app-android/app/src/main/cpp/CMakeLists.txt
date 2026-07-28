# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.28)
project(Passepartout LANGUAGES C)
set(CMAKE_C_FLAGS "-W -Wall -Werror -pedantic")

# Global constants
set(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../..")
set(USE_OPENSSL ON)
set(USE_MBEDTLS OFF)

# Define wrapper
add_library(passepartout_wrapper SHARED "")

# Set up Partout folders
set(PARTOUT_ROOT ${PROJECT_ROOT}/partout)
set(PARTOUT_OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/bin)

# Configure Partout
set(PP_BUILD_OUTPUT "${PARTOUT_OUTPUT}")
set(PP_BUILD_LIBRARY ON)
set(PP_BUILD_USE_OPENVPN ON)
set(PP_BUILD_USE_WIREGUARD ON)
set(PP_BUILD_USE_OPENSSL ${USE_OPENSSL})
set(PP_BUILD_USE_MBEDTLS ${USE_MBEDTLS})
set(PP_BUILD_VENDOR_SOURCE bundled)

# Configure build outputs
set(PARTOUT_LIBRARY ${PARTOUT_OUTPUT}/partout/libpartout.so)
set(PARTOUT_VENDOR_LIBRARIES "")
list(APPEND PARTOUT_VENDOR_LIBRARIES
        ${PARTOUT_OUTPUT}/wg-go/lib/libwg-go.so
)
if(USE_OPENSSL)
    list(APPEND PARTOUT_VENDOR_LIBRARIES
            ${PARTOUT_OUTPUT}/openssl/lib/libcrypto.so
            ${PARTOUT_OUTPUT}/openssl/lib/libssl.so
    )
endif()

# Include subproject
add_subdirectory("${PARTOUT_ROOT}" partout)

# Merge with wrapper
target_link_libraries(passepartout_wrapper PRIVATE partout android log)
set(PARTOUT_LIBRARIES
        ${PARTOUT_LIBRARY}
        ${PARTOUT_VENDOR_LIBRARIES}
)
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
