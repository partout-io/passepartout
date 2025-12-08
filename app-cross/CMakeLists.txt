cmake_minimum_required(VERSION 3.27)
project(PassepartoutCross LANGUAGES C CXX Swift)

# Output
set(PSP_OUT "${OUTPUT_DIR}/app")

# Define target and output
add_executable(passepartout "")
set_target_properties(passepartout PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${PSP_OUT}
    ARCHIVE_OUTPUT_DIRECTORY ${PSP_OUT}
    RUNTIME_OUTPUT_DIRECTORY ${PSP_OUT}
)

# Compile app files
file(GLOB_RECURSE PSP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc)
target_sources(passepartout PRIVATE ${PSP_SOURCES})

# Include app headers plus former ABI outputs
target_include_directories(passepartout PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${OUTPUT_DIR}
)

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
endif()

# Link to shared library
target_link_directories(passepartout PRIVATE ${OUTPUT_DIR})
target_link_libraries(passepartout PRIVATE passepartout_shared)

# Link to wxWidgets
include("wx.cmake")

# Strip executable except on Windows
if(NOT WIN32)
    add_custom_command(
        TARGET passepartout
        POST_BUILD
        COMMAND ${CMAKE_STRIP} $<TARGET_FILE:passepartout>
    )
endif()
