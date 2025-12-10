cmake_minimum_required(VERSION 3.27)
project(PassepartoutCross LANGUAGES C CXX)

# Output
set(PSP_OUT "${OUTPUT_DIR}/app")

# Define target and output
add_executable(passepartout "")
add_executable(passepartout-tunnel "")
set_target_properties(passepartout PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${PSP_OUT}
    ARCHIVE_OUTPUT_DIRECTORY ${PSP_OUT}
    RUNTIME_OUTPUT_DIRECTORY ${PSP_OUT}
)
set_target_properties(passepartout-tunnel PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${PSP_OUT}
    ARCHIVE_OUTPUT_DIRECTORY ${PSP_OUT}
    RUNTIME_OUTPUT_DIRECTORY ${PSP_OUT}
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
if(NOT WIN32)
    add_custom_command(
        TARGET passepartout
        POST_BUILD
        COMMAND ${CMAKE_STRIP} $<TARGET_FILE:passepartout>
    )
    add_custom_command(
        TARGET passepartout-tunnel
        POST_BUILD
        COMMAND ${CMAKE_STRIP} $<TARGET_FILE:passepartout-tunnel>
    )
endif()
