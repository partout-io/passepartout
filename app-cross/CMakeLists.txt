cmake_minimum_required(VERSION 3.28)
if(POLICY CMP0177)
    cmake_policy(SET CMP0177 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0177 NEW)
endif()
project(Passepartout)

if(NOT OUTPUT_DIR)
    set(OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
endif()

# Depend on Partout
set(PP_BUILD_OUTPUT ${OUTPUT_DIR})
set(PP_BUILD_LIBRARY ON)
set(PP_BUILD_USE_OPENSSL ON)
set(PP_BUILD_USE_MBEDTLS OFF)
set(PP_BUILD_USE_OPENVPN ON)
set(PP_BUILD_USE_WIREGUARD ON)

add_subdirectory(../partout partout)

# Include file lists
include("passepartout.cmake")

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
        ${OUTPUT_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/app/include
    )
    target_link_libraries(passepartout PRIVATE partout)

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
target_sources(passepartout-tunnel PRIVATE ${TUNNEL_SOURCES})
target_include_directories(passepartout-tunnel PRIVATE
    ${OUTPUT_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/tunnel/include
)
target_link_libraries(passepartout-tunnel PRIVATE partout)
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

install(CODE [[
    file(GLOB_RECURSE PARTOUT_DEVELOPMENT_OUTPUTS
        LIST_DIRECTORIES false
        "${CMAKE_INSTALL_PREFIX}/*.h"
        "${CMAKE_INSTALL_PREFIX}/*.lib"
    )
    if(PARTOUT_DEVELOPMENT_OUTPUTS)
        file(REMOVE ${PARTOUT_DEVELOPMENT_OUTPUTS})
    endif()
    file(REMOVE_RECURSE
        "${CMAKE_INSTALL_PREFIX}/include"
        "${CMAKE_INSTALL_PREFIX}/cmake"
    )
]])

if(WIN32)
    install(CODE
        "set(SWIFT_ROOT [==[${SWIFT_ROOT}]==])
set(SWIFT_VERSION [==[${SWIFT_VERSION}]==])
include([==[${CMAKE_CURRENT_SOURCE_DIR}/../cmake/swift-macros.cmake]==])
swift_copy_windows_runtime(\"\${CMAKE_INSTALL_PREFIX}\")"
    )
endif()

