# Configure as shared library
add_library(passepartout_shared SHARED "")

# Include file lists
include("passepartout_shared.cmake")

set(PSP_ABI_INPUTS
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CommonLibrary_C/include/passepartout.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CommonLibrary_C/include/module.modulemap
)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${PSP_ABI_INPUTS})
set(PSP_ABI_INPUTS_HASH "")
foreach(input IN LISTS PSP_ABI_INPUTS)
    file(SHA256 ${input} input_hash)
    string(APPEND PSP_ABI_INPUTS_HASH "${input_hash}\n")
endforeach()
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/passepartout_shared.swift.in
    ${CMAKE_CURRENT_BINARY_DIR}/generated/passepartout_shared.swift
    @ONLY
)

target_compile_options(passepartout_shared PRIVATE
    -DUSE_CMAKE
)
set_target_properties(passepartout_shared PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    OUTPUT_NAME passepartout
    Swift_COMPILATION_MODE incremental
)

# Build Partout dependency
set(PP_BUILD_OUTPUT ${OUTPUT_DIR})
set(PP_BUILD_LIBRARY ON)
set(PP_BUILD_USE_OPENSSL ON)
set(PP_BUILD_USE_OPENVPN ON)
set(PP_BUILD_USE_WIREGUARD ON)
add_subdirectory(partout)

# Set exclusions and symbols for non-Apple builds
set(PSP_EXCLUSIONS CommonData.*)
target_compile_options(passepartout_shared PRIVATE -DPSP_ABI)
if(NOT APPLE)
    target_compile_options(passepartout_shared PRIVATE -DPSP_CROSS)
    list(APPEND PSP_EXCLUSIONS CommonLibraryApple.*)
endif()
foreach(pattern ${PSP_EXCLUSIONS})
    list(FILTER PSP_SOURCES EXCLUDE REGEX ${pattern})
endforeach()
target_sources(passepartout_shared PRIVATE
    ${PSP_SOURCES}
    ${CMAKE_CURRENT_BINARY_DIR}/generated/passepartout_shared.swift
)

# Link the C ABI code
add_library(passepartout_shared_c STATIC ${PSP_C_SOURCES})
target_link_libraries(passepartout_shared PUBLIC passepartout_shared_c)

# Import the modulemap for the C ABI
target_include_directories(passepartout_shared_c PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CommonLibrary_C/include
)

# Depend on Partout
add_dependencies(passepartout_shared partout)
target_include_directories(passepartout_shared PRIVATE ${OUTPUT_DIR}/partout)
target_link_libraries(passepartout_shared PRIVATE
    partout
    $<TARGET_OBJECTS:partout_c>
)
# if(LINUX OR ANDROID)
#    target_link_options(passepartout_shared PRIVATE "LINKER:-z,defs")
# endif()

# Configure Linux RPATH stuff
if(LINUX)
    set_target_properties(passepartout_shared PROPERTIES
        BUILD_RPATH "\$ORIGIN"
        INSTALL_RPATH "\$ORIGIN"
        SKIP_BUILD_RPATH OFF
    )
endif()

# Distribute with dependencies
if(WIN32)
    set(LIBEXT lib)
elseif(APPLE)
    set(LIBEXT dylib)
else()
    set(LIBEXT so)
endif()
add_custom_command(
    TARGET passepartout_shared
    POST_BUILD
    COMMAND ${CMAKE_COMMAND}
        -DOUTPUT_DIR=${OUTPUT_DIR}
        -DDIST_DIR=${DIST_DIR}
        -DSTRIP=${CMAKE_STRIP}
        -DLIBEXT=${LIBEXT}
        -P "${CMAKE_CURRENT_SOURCE_DIR}/distribute.cmake"
)

# Build end-user applications
add_subdirectory(passepartout)
