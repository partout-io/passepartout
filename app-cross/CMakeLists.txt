cmake_minimum_required(VERSION 3.27)
project(PassepartoutCross LANGUAGES C CXX)

# Define target and output
add_executable(passepartout "")
add_executable(passepartout-tunnel "")
set_target_properties(passepartout PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR}
)
set_target_properties(passepartout-tunnel PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR}
)

# Compile app files
file(GLOB_RECURSE APP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/app/*.cc)
file(GLOB_RECURSE TUNNEL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/tunnel/*.c)
target_sources(passepartout PRIVATE ${APP_SOURCES})
target_sources(passepartout-tunnel PRIVATE ${TUNNEL_SOURCES})

# Include app headers plus former ABI outputs
target_include_directories(passepartout PRIVATE ${OUTPUT_DIR})
target_include_directories(passepartout-tunnel PRIVATE ${OUTPUT_DIR})

if(WIN32)
    # Build WinMain app
    set_target_properties(passepartout PROPERTIES WIN32_EXECUTABLE ON)
elseif(LINUX)
    # Configure Linux RPATH stuff
    set_target_properties(passepartout PROPERTIES
        BUILD_RPATH "\$ORIGIN"
        INSTALL_RPATH "\$ORIGIN"
        SKIP_BUILD_RPATH OFF
    )
    set_target_properties(passepartout-tunnel PROPERTIES
        BUILD_RPATH "\$ORIGIN"
        INSTALL_RPATH "\$ORIGIN"
        SKIP_BUILD_RPATH OFF
    )
endif()

# Link to shared library
find_library(LIBSHARED REQUIRED
    NAMES passepartout libpassepartout
    HINTS ${OUTPUT_DIR}
)
target_link_libraries(passepartout PRIVATE ${LIBSHARED})
target_link_libraries(passepartout-tunnel PRIVATE ${LIBSHARED})

# Link to wxWidgets
include("wx.cmake")

# Strip executables except on Windows
set(APP_DIR ${OUTPUT_DIR}/${DIST_DIR})
if(WIN32)
    set(STRIP rem)
else()
    set(STRIP ${CMAKE_STRIP})
endif()
add_custom_command(
    TARGET passepartout
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:passepartout> ${APP_DIR}
    COMMAND ${STRIP} ${APP_DIR}/passepartout
)
add_custom_command(
    TARGET passepartout-tunnel
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:passepartout-tunnel> ${APP_DIR}
    COMMAND ${STRIP} ${APP_DIR}/passepartout-tunnel
)
