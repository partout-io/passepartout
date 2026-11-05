# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: GPL-3.0

cmake_minimum_required(VERSION 3.28)
# Select per-target MSVC runtime checks before enabling any languages.
if(POLICY CMP0184)
    cmake_policy(SET CMP0184 NEW)
endif()
if(POLICY CMP0177)
    cmake_policy(SET CMP0177 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0177 NEW)
endif()
project(Passepartout LANGUAGES C CXX)

# No target uses C++ modules, including the C++20 WinRT bridge. Avoid
# unnecessary dyndep scanning, which can assert in Ninja on rebuilds.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

if(WIN32)
    if(NOT MSVC OR CMAKE_VERSION VERSION_LESS 4.0)
        message(FATAL_ERROR "Windows requires MSVC, the Windows SDK, and CMake 4.0 or newer")
    endif()
    string(TOLOWER "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}" PASSEPARTOUT_WINDOWS_ARCH)
    if(PASSEPARTOUT_WINDOWS_ARCH MATCHES "^(x64|amd64)$")
        set(PASSEPARTOUT_WINDOWS_ARCH x64)
    elseif(NOT PASSEPARTOUT_WINDOWS_ARCH STREQUAL "arm64")
        message(FATAL_ERROR "Unsupported Windows architecture: ${PASSEPARTOUT_WINDOWS_ARCH}")
    endif()
endif()

option(BUILD_APP "Build app executable" OFF)

include("${CMAKE_CURRENT_SOURCE_DIR}/../cmake/prebuilts.cmake")
if(NOT PP_BUILD_VENDOR_PREBUILT_URL)
    set(PP_BUILD_VENDOR_PREBUILT_URL "${PASSEPARTOUT_PREBUILTS_URL}")
endif()
if(NOT PASSEPARTOUT_WX_PREBUILT_BASE_URL)
    set(PASSEPARTOUT_WX_PREBUILT_BASE_URL "${PASSEPARTOUT_PREBUILTS_URL}")
endif()

if(MSVC AND NOT CMAKE_MSVC_RUNTIME_LIBRARY)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
endif()

if(NOT OUTPUT_DIR)
    set(OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
endif()

# Depend on Partout
set(PP_BUILD_OUTPUT "${OUTPUT_DIR}")
# Use native cryptography backed by mbedTLS; do not build OpenSSL.
set(PP_BUILD_USE_OPENSSL OFF)
set(PP_BUILD_USE_MBEDTLS ON)
set(PP_BUILD_USE_OPENVPN ON)
set(PP_BUILD_USE_WIREGUARD ON)
if(WIN32)
    set(PP_BUILD_WINDOWS ON)
    # Stop the packaged host before replacing its shared dependencies.
    find_program(PLUGIN_POWERSHELL NAMES powershell.exe REQUIRED)
    set(PLUGIN_STOP_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/tunnel/stop-plugin.ps1")
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/tunnel/stop-plugin.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/tunnel/stop-plugin.cmake" @ONLY)
    install(SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/tunnel/stop-plugin.cmake")
endif()

add_subdirectory(../partout partout)

# App and plugin runtime outputs share the selected directory.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${OUTPUT_DIR}")

function(target_link_partout target)
    if(WIN32)
        target_link_libraries(${target} PRIVATE Partout::WindowsRuntime)
    else()
        target_link_libraries(${target} PRIVATE Partout::Partout)
    endif()
    if(LINUX)
        target_link_options(${target} PRIVATE
            "LINKER:-rpath-link,${PP_BUILD_OUTPUT}/wg-go/lib"
        )
    endif()
endfunction()

# Include file lists
include("files.cmake")

# Define app target
if(BUILD_APP)
    include("core.cmake")
    add_executable(passepartout ${APP_SOURCES})
    target_include_directories(passepartout PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/app/include"
    )
    target_link_partout(passepartout)
    target_link_libraries(passepartout PRIVATE passepartout-core)
    if(WIN32)
        target_link_libraries(passepartout PRIVATE windowsapp runtimeobject)
        target_compile_definitions(passepartout PRIVATE NOMINMAX)
        target_compile_options(passepartout PRIVATE /EHsc /permissive- /utf-8)
    endif()

    # wxWidgets only required to build app executable
    include("wx.cmake")
    target_precompile_headers(passepartout PRIVATE <wx/wx.h>)

    if(APPLE)
        set_target_properties(passepartout PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_BUNDLE_NAME "Passepartout"
            MACOSX_BUNDLE_GUI_IDENTIFIER "io.partout.passepartout.cross"
        )
    endif()

    install(TARGETS passepartout
        RUNTIME DESTINATION .
        BUNDLE DESTINATION .
    )
    if(APPLE)
        # Bundle the installed Partout runtime and wxWidgets dependencies.
        install(CODE [[
            include(BundleUtilities)
            fixup_bundle("${CMAKE_INSTALL_PREFIX}/passepartout.app" "" "${CMAKE_INSTALL_PREFIX}")
        ]])
    endif()
    if(MSVC)
        install(FILES "$<TARGET_PDB_FILE:passepartout>"
            DESTINATION . CONFIGURATIONS Debug RelWithDebInfo OPTIONAL
        )
    endif()
endif()

# Define tunnel target
add_executable(passepartout-tunnel "")
if(WIN32)
    target_sources(passepartout-tunnel PRIVATE tunnel/main_windows.cc)
else()
    target_sources(passepartout-tunnel PRIVATE tunnel/main_posix.c tunnel/common.c)
endif()
if(NOT WIN32)
    target_link_partout(passepartout-tunnel)
    target_link_libraries(passepartout-tunnel PRIVATE Partout::PosixRuntime)
endif()
# Apply native executable settings once to both entry points.
set(APP_TARGETS passepartout-tunnel)
if(BUILD_APP)
    list(APPEND APP_TARGETS passepartout)
endif()
foreach(APP_TARGET IN LISTS APP_TARGETS)
    if(WIN32)
        set_target_properties(${APP_TARGET} PROPERTIES WIN32_EXECUTABLE ON)
    elseif(APPLE)
        set_target_properties(${APP_TARGET} PROPERTIES
            MACOSX_RPATH ON
            BUILD_WITH_INSTALL_RPATH TRUE
            INSTALL_RPATH "@loader_path"
            INSTALL_NAME_DIR "@rpath"
        )
    elseif(LINUX)
        set_target_properties(${APP_TARGET} PROPERTIES
            BUILD_RPATH "$ORIGIN"
            INSTALL_RPATH "$ORIGIN"
            SKIP_BUILD_RPATH OFF
        )
    endif()
endforeach()
install(TARGETS passepartout-tunnel
    RUNTIME DESTINATION .
)

include("tunnel/plugin.cmake")
include("package.cmake")
