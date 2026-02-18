cmake_minimum_required(VERSION 3.27)
project(Passepartout)
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
    set(SWIFTLY_ARGS
        -DCMAKE_Swift_COMPILER=${CMAKE_CURRENT_SOURCE_DIR}/submodules/partout/toolchains/swiftc-wrapper.sh
    )
endif()

# Build Partout dependency
set(PARTOUT_ARGS
    ${BUILD_ARGS}
    ${TOOLCHAIN_ARGS}
    -DPP_BUILD_OUTPUT=${OUTPUT_DIR}
    -DPP_BUILD_LIBRARY=ON
    -DPP_BUILD_USE_OPENSSL=ON
    -DPP_BUILD_USE_WGGO=ON
)
ExternalProject_Add(
    PartoutProject
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/submodules/partout
    CMAKE_ARGS ${PARTOUT_ARGS}
    INSTALL_COMMAND ""
    BUILD_ALWAYS 0
)

# Build Passepartout shared library
set(ABI_ARGS
    ${BUILD_ARGS}
    ${TOOLCHAIN_ARGS}
    ${SWIFTLY_ARGS}
    -DOUTPUT_DIR=${OUTPUT_DIR}
    -DDIST_DIR=${DIST_DIR}
)
ExternalProject_Add(
    PassepartoutShared
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/app-shared
    CMAKE_ARGS ${ABI_ARGS}
    INSTALL_COMMAND ""
    BUILD_ALWAYS 1
    DEPENDS PartoutProject
)

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
    ExternalProject_Add(
        wxWidgets
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/submodules/wx
        CMAKE_GENERATOR ${WX_GENERATOR}
        CMAKE_ARGS ${WX_ARGS}
        BUILD_COMMAND ""
        INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
    )
    ExternalProject_Add(
        PassepartoutApp
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/app-cross
        CMAKE_ARGS ${BUILD_ARGS} -DOUTPUT_DIR=${OUTPUT_DIR} -DDIST_DIR=${DIST_DIR}
        INSTALL_COMMAND ""
        BUILD_ALWAYS 1
        DEPENDS wxWidgets PassepartoutShared
    )
endif()
