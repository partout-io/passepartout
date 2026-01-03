cmake_minimum_required(VERSION 3.27)
project(PassepartoutShared LANGUAGES Swift)

# Configure as shared library
add_library(passepartout_shared SHARED "")
file(GLOB_RECURSE PSP_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/*.swift
)
foreach(pattern ${PSP_EXCLUSIONS})
    list(FILTER PSP_SOURCES EXCLUDE REGEX ${pattern})
endforeach()
target_sources(passepartout_shared PRIVATE ${PSP_SOURCES})
target_compile_options(passepartout_shared PRIVATE
    -DUSE_CMAKE
)
set_target_properties(passepartout_shared PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    OUTPUT_NAME passepartout
)

# Set exclusions and symbols for non-Apple builds
if(NOT APPLE)
    target_compile_options(passepartout_shared PRIVATE
        -DPSP_CROSS
    )
    set(PSP_EXCLUSIONS
        CommonData.*
        CommonLibraryApple.*
    )
endif()

# Import Partout as a Swift module plus the modulemap for the C ABI
set(ABI_INCLUDE ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CommonLibraryCore_C/include)
target_include_directories(passepartout_shared PRIVATE
    ${ABI_INCLUDE}
    ${OUTPUT_DIR}/partout
    ${OUTPUT_DIR}/partout/modules
)
target_link_directories(passepartout_shared PRIVATE
    ${OUTPUT_DIR}/partout
)

# Link Partout static library
message(STATUS "Searching for libraries in ${OUTPUT_DIR}")
# Android CMake can't seem to find static libraries, smh
if(ANDROID)
    target_link_libraries(passepartout_shared PRIVATE
        partout
        partout_c
    )
else()
    find_library(LIBPARTOUT REQUIRED
        NAMES partout libpartout
        HINTS ${OUTPUT_DIR}/partout
    )
    find_library(LIBPARTOUT_C REQUIRED
        NAMES partout_c libpartout_c
        HINTS ${OUTPUT_DIR}/partout
    )
    target_link_libraries(passepartout_shared PRIVATE
        ${LIBPARTOUT}
        ${LIBPARTOUT_C}
    )
endif()

# Link dynamic vendors
#
# CAVEATS:
# - libs order MATTERS!
# - use explicit paths to avoid linking issues at runtime
# - find_library() works around OS-specific extensions
#
# For example, passing "ssl" and "crypto" would likely link
# to the system-wide OpenSSL and result in obscure crashes
# at runtime due to binary mismatch
#
# Damn it, find_library() is unreliable
if(WIN32)
    set(LIBEXT lib)
elseif(APPLE)
    set(LIBEXT dylib)
else()
    set(LIBEXT so)
endif()
target_link_libraries(passepartout_shared PRIVATE
    ${OUTPUT_DIR}/openssl/lib/libssl.${LIBEXT}
    ${OUTPUT_DIR}/openssl/lib/libcrypto.${LIBEXT}
    ${OUTPUT_DIR}/wg-go/lib/libwg-go.${LIBEXT}
)

# Distribute with dependencies
if(ANDROID)
    set(STRIP llvm-strip)
else()
    set(STRIP ${CMAKE_STRIP})
endif()
add_custom_command(
    TARGET passepartout_shared
    POST_BUILD
    COMMAND ${CMAKE_COMMAND}
        -DABI_INCLUDE=${ABI_INCLUDE}
        -DOUTPUT_DIR=${OUTPUT_DIR}
        -DDIST_DIR=${DIST_DIR}
        -DSTRIP=${STRIP} -DLIBEXT=${LIBEXT}
        -P "${CMAKE_CURRENT_SOURCE_DIR}/distribute.cmake"
)
