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

if(WIN32 AND CMAKE_VERSION VERSION_LESS 4.0)
    message(FATAL_ERROR "The Windows WinRT build requires CMake 4.0 or newer")
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
    set(OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
endif()

# Depend on Partout
set(PP_BUILD_OUTPUT ${OUTPUT_DIR})
set(PP_BUILD_USE_OPENSSL ON)
set(PP_BUILD_USE_MBEDTLS ON)
set(PP_BUILD_USE_OPENVPN ON)
set(PP_BUILD_USE_WIREGUARD ON)
if(WIN32)
    set(PP_BUILD_WINRT ON)
    # Stop the packaged host before replacing its shared dependencies.
    find_program(PLUGIN_POWERSHELL NAMES powershell.exe REQUIRED)
    set(PLUGIN_STOP_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/tunnel/stop-plugin.ps1")
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/tunnel/stop-plugin.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/tunnel/stop-plugin.cmake" @ONLY)
    install(SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/tunnel/stop-plugin.cmake")
endif()

add_subdirectory(../partout partout)

function(target_link_partout target)
    add_dependencies(${target} partout)
    target_link_libraries(${target} PRIVATE Partout::Partout)
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
    add_executable(passepartout "")
    set_target_properties(passepartout PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}
        ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}
        RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    )
    target_sources(passepartout PRIVATE ${APP_SOURCES})
    target_include_directories(passepartout PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/app/include
    )
    target_link_partout(passepartout)

    # wxWidgets only required to build app executable
    include("wx.cmake")
    target_precompile_headers(passepartout PRIVATE <wx/wx.h>)

    if(APPLE)
        # Mangle macOS @rpath
        set_target_properties(passepartout PROPERTIES
            MACOSX_RPATH ON
            BUILD_WITH_INSTALL_RPATH TRUE
            INSTALL_RPATH "@loader_path"
            INSTALL_NAME_DIR "@rpath"
        )
    elseif(LINUX)
        # Mangle Linux RPATH
        set_target_properties(passepartout PROPERTIES
            BUILD_RPATH "\$ORIGIN"
            INSTALL_RPATH "\$ORIGIN"
            SKIP_BUILD_RPATH OFF
        )
    elseif(WIN32)
        # Build WinMain app
        set_target_properties(passepartout PROPERTIES WIN32_EXECUTABLE ON)
    endif()

    install(TARGETS passepartout
        RUNTIME DESTINATION .
    )
endif()

# Define tunnel target
add_executable(passepartout-tunnel "")
set_target_properties(passepartout-tunnel PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR}
)
if(WIN32)
    target_sources(passepartout-tunnel PRIVATE tunnel/main_windows.cc)
    set_target_properties(passepartout-tunnel PROPERTIES WIN32_EXECUTABLE ON)
else()
    target_sources(passepartout-tunnel PRIVATE tunnel/main_linux.c)
endif()
target_include_directories(passepartout-tunnel PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/tunnel/include
)
if(NOT WIN32)
    target_link_partout(passepartout-tunnel)
endif()
if(APPLE)
    set_target_properties(passepartout-tunnel PROPERTIES
        MACOSX_RPATH ON
        BUILD_WITH_INSTALL_RPATH TRUE
        INSTALL_RPATH "@loader_path"
        INSTALL_NAME_DIR "@rpath"
    )
elseif(LINUX)
    set_target_properties(passepartout-tunnel PROPERTIES
        BUILD_RPATH "\$ORIGIN"
        INSTALL_RPATH "\$ORIGIN"
        SKIP_BUILD_RPATH OFF
    )
endif()
install(TARGETS passepartout-tunnel
    RUNTIME DESTINATION .
)

include("tunnel/plugin.cmake")
