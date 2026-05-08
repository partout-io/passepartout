# Configure as shared library
add_library(libpassepartout SHARED "")

# Include file lists
include("libpassepartout.cmake")

target_compile_options(libpassepartout PRIVATE
    -DUSE_CMAKE
)
set_target_properties(libpassepartout PROPERTIES
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
set(PP_BUILD_USE_WGGO ON)
add_subdirectory(partout)

# Set exclusions and symbols for non-Apple builds
set(PSP_EXCLUSIONS CommonData.*)
target_compile_options(libpassepartout PRIVATE -DPSP_ABI)
if(NOT APPLE)
    target_compile_options(libpassepartout PRIVATE -DPSP_CROSS)
    list(APPEND PSP_EXCLUSIONS CommonLibraryApple.*)
endif()
foreach(pattern ${PSP_EXCLUSIONS})
    list(FILTER PSP_SOURCES EXCLUDE REGEX ${pattern})
endforeach()
target_sources(libpassepartout PRIVATE ${PSP_SOURCES})

# Link the C ABI code
add_library(libpassepartout_c STATIC ${PSP_C_SOURCES})
target_link_libraries(libpassepartout PUBLIC libpassepartout_c)

# Import the modulemap for the C ABI
set(ABI_INCLUDE ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CommonLibrary_C/include)
target_include_directories(libpassepartout PUBLIC ${ABI_INCLUDE})

# Depend on Partout
add_dependencies(libpassepartout partout)
target_include_directories(libpassepartout PRIVATE ${OUTPUT_DIR}/partout)
target_link_libraries(libpassepartout PRIVATE
    partout
    $<TARGET_OBJECTS:partout_c>
)
# if(LINUX OR ANDROID)
#    target_link_options(libpassepartout PRIVATE "LINKER:-z,defs")
# endif()

# Configure Linux RPATH stuff
if(LINUX)
    set_target_properties(libpassepartout PROPERTIES
        BUILD_RPATH "\$ORIGIN"
        INSTALL_RPATH "\$ORIGIN"
        SKIP_BUILD_RPATH OFF
    )
endif()

# Distribute with dependencies
if(ANDROID)
    set(STRIP "${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-strip")
else()
    set(STRIP ${CMAKE_STRIP})
endif()
if(WIN32)
    set(LIBEXT lib)
elseif(APPLE)
    set(LIBEXT dylib)
else()
    set(LIBEXT so)
endif()
add_custom_command(
    TARGET libpassepartout
    POST_BUILD
    COMMAND ${CMAKE_COMMAND}
        -DABI_INCLUDE=${ABI_INCLUDE}
        -DOUTPUT_DIR=${OUTPUT_DIR}
        -DDIST_DIR=${DIST_DIR}
        -DSTRIP=${STRIP} -DLIBEXT=${LIBEXT}
        -P "${CMAKE_CURRENT_SOURCE_DIR}/distribute.cmake"
)

# Optionally build end-user applications
if(BUILD_APP)
    add_subdirectory(passepartout)
endif()
