set(CMAKE_C_FLAGS "-Wall -W -pedantic")
set(CMAKE_CXX_FLAGS "-Wall -W -pedantic")

# Depend on Partout
set(PP_BUILD_OUTPUT ${OUTPUT_DIR})
set(PP_BUILD_LIBRARY ON)
set(PP_BUILD_USE_OPENSSL ON)
set(PP_BUILD_USE_OPENVPN ON)
set(PP_BUILD_USE_WIREGUARD ON)
add_subdirectory(../partout partout)

# Include file lists
include("passepartout.cmake")
set(APP_DIR ${DIST_DIR})

# Strip executables except on Windows
if(WIN32)
    set(STRIP rem)
else()
    set(STRIP ${CMAKE_STRIP})
endif()

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

    # Distribute
    add_custom_command(
        TARGET passepartout
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:passepartout>"
            "${APP_DIR}/$<TARGET_FILE_NAME:passepartout>"
        COMMAND ${STRIP} "${APP_DIR}/$<TARGET_FILE_NAME:passepartout>"
        VERBATIM
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
add_custom_command(
    TARGET passepartout-tunnel
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:passepartout-tunnel>"
        "${APP_DIR}/$<TARGET_FILE_NAME:passepartout-tunnel>"
    COMMAND ${STRIP} "${APP_DIR}/$<TARGET_FILE_NAME:passepartout-tunnel>"
    VERBATIM
)
