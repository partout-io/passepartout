cmake_minimum_required(VERSION 3.27)
project(PassepartoutShared LANGUAGES Swift)

# Include CommonLibrary sources
file(GLOB_RECURSE PSP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Sources/*.swift)
set(PSP_EXCLUSIONS
    CommonLibraryApple.*
    CommonProviders.*
)
foreach(pattern ${PSP_EXCLUSIONS})
    list(FILTER PSP_SOURCES EXCLUDE REGEX ${pattern})
endforeach()

# Configure as static library except on Android
add_library(passepartout_shared SHARED ${PSP_SOURCES})
target_compile_options(passepartout_shared PRIVATE
    -DPSP_CROSS
)
set_target_properties(passepartout_shared PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    OUTPUT_NAME passepartout
)

include("distribute.cmake")

# Import Partout as a Swift module plus the modulemap for the C ABI
target_include_directories(passepartout_shared PRIVATE
    ${OUTPUT_DIR}/partout
    ${OUTPUT_DIR}/partout/modules
)
target_link_directories(passepartout_shared PRIVATE
    ${OUTPUT_DIR}/partout
)

# Link Partout static library into dynamic library
if(WIN32)
    target_link_libraries(passepartout_shared PRIVATE
        ${OUTPUT_DIR}/partout/libpartout.lib
        ${OUTPUT_DIR}/partout/libpartout_c.lib
        ${OUTPUT_DIR}/openssl/lib/libssl.lib
        ${OUTPUT_DIR}/openssl/lib/libcrypto.lib
    )
else()
    target_link_directories(passepartout_shared PRIVATE
        ${OUTPUT_DIR}/partout
        ${OUTPUT_DIR}/openssl/lib
        ${OUTPUT_DIR}/wg-go/lib
    )
    target_link_libraries(passepartout_shared PRIVATE
        partout
        partout_c
        ssl
        crypto
        wg-go
    )
endif()

# Distribute with dependencies
add_custom_command(
    TARGET passepartout_shared
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_SOURCE_DIR}/distribute.cmake" "${OUTPUT_DIR}"
)
