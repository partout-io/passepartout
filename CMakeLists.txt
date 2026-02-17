cmake_minimum_required(VERSION 3.27)
project(Passepartout LANGUAGES Swift C CXX)
include(ExternalProject)

option(BUILD_APP "Build app executable" 0)

# Configure output location
get_filename_component(OUTPUT_DIR "bin/${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}" ABSOLUTE)
string(TOLOWER "${OUTPUT_DIR}" OUTPUT_DIR)
set(DIST_DIR "dist")

# Options
message(STATUS "Option OUTPUT_DIR = ${OUTPUT_DIR}")
message(STATUS "Option BUILD_APP = ${BUILD_APP}")

# Propagate CMake args
set(BUILD_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})
if(DEFINED CMAKE_TOOLCHAIN_FILE)
    set(TOOLCHAIN_ARGS
        -DCMAKE_TOOLCHAIN_FILE:FILEPATH=${CMAKE_TOOLCHAIN_FILE}
    )
endif()

# Build Passepartout shared library
set(ABI_ARGS
    ${BUILD_ARGS}
    ${TOOLCHAIN_ARGS}
    -DOUTPUT_DIR=${OUTPUT_DIR}
    -DDIST_DIR=${DIST_DIR}
)
add_subdirectory(app-shared)

# wxWidgets only required to build executable
if(BUILD_APP)
    if(WIN32)
        set(WX_GENERATOR "Visual Studio 17 2022")
    else()
        set(WX_GENERATOR ${CMAKE_GENERATOR})
    endif()
    set(WX_ARGS
        -DCMAKE_INSTALL_PREFIX=${OUTPUT_DIR}/wx
        -DwxBUILD_SHARED=OFF
        -DwxBUILD_TESTS=OFF
        -DwxBUILD_SAMPLES=OFF
        -DwxBUILD_DEMOS=OFF
        -DwxBUILD_PRECOMP=OFF
        -DwxUSE_LIBWEBP=OFF
        -DwxUSE_WEBVIEW=OFF
    )
    ExternalProject_Add(wxWidgets
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/submodules/wx
        CMAKE_GENERATOR ${WX_GENERATOR}
        CMAKE_ARGS ${WX_ARGS}
        BUILD_COMMAND ""
        INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
    )
    add_subdirectory(app-cross)
    add_dependencies(passepartout wxWidgets passepartout_shared)
    add_dependencies(passepartout-tunnel passepartout_shared)
endif()
