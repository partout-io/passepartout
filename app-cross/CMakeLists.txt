# Configure as shared library
add_library(passepartout_shared SHARED "")
file(GLOB_RECURSE PSP_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/*.swift
)
target_compile_options(passepartout_shared PRIVATE
    -DUSE_CMAKE
)
set_target_properties(passepartout_shared PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    OUTPUT_NAME passepartout
)

# Build Partout dependency
set(PP_BUILD_OUTPUT ${OUTPUT_DIR})
set(PP_BUILD_LIBRARY ON)
set(PP_BUILD_USE_OPENSSL ON)
set(PP_BUILD_USE_WGGO ON)
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
target_sources(passepartout_shared PRIVATE ${PSP_SOURCES})

# Link the C ABI code
file(GLOB_RECURSE PSP_C_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CommonLibrary_C/*.c)
add_library(passepartout_shared_c STATIC ${PSP_C_SOURCES})
target_link_libraries(passepartout_shared PUBLIC passepartout_shared_c)

# Import the modulemap for the C ABI
set(ABI_INCLUDE ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CommonLibrary_C/include)
target_include_directories(passepartout_shared PUBLIC ${ABI_INCLUDE})

# Depend on Partout
add_dependencies(passepartout_shared partout)
target_include_directories(passepartout_shared PRIVATE ${OUTPUT_DIR}/partout)
target_link_libraries(passepartout_shared PRIVATE partout)

# Configure Linux RPATH stuff
if(LINUX)
    set_target_properties(passepartout_shared PROPERTIES
        BUILD_RPATH "\$ORIGIN"
        INSTALL_RPATH "\$ORIGIN"
        SKIP_BUILD_RPATH OFF
    )
endif()

# Distribute with dependencies
if(ANDROID)
    set(STRIP llvm-strip)
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
    TARGET passepartout_shared
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
