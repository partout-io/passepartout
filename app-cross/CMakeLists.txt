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

include("passepartout.cmake")
include("wx.cmake")
include("swift.cmake")

# Distribute with dependencies
add_custom_command(
    TARGET passepartout
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_SOURCE_DIR}/distribute.cmake" "${OUTPUT_DIR}" "${PSP_OUT}"
)

# Strip executable except on Windows
if(NOT WIN32)
    add_custom_command(
        TARGET passepartout
        POST_BUILD
        COMMAND ${CMAKE_STRIP} $<TARGET_FILE:passepartout>
    )
endif()
