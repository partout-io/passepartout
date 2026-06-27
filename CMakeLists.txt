cmake_minimum_required(VERSION 3.28)
if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW)
endif()
if(POLICY CMP0157)
    cmake_policy(SET CMP0157 NEW)
endif()
project(PassepartoutProject LANGUAGES Swift C CXX)
include(ExternalProject)

option(BUILD_APP "Build app executable" 0)

if(MSVC AND NOT CMAKE_MSVC_RUNTIME_LIBRARY)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
endif()

# Configure output location
if(NOT DEFINED OUTPUT_DIR)
    string(TOLOWER "${CMAKE_SYSTEM_NAME}" PLATFORM_NAME)
    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" ARCH_NAME)
    set(OUTPUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/bin/${PLATFORM_NAME}-${ARCH_NAME}")
endif()

# Options
message(STATUS "Option OUTPUT_DIR = ${OUTPUT_DIR}")
message(STATUS "Option BUILD_APP = ${BUILD_APP}")

# Build cross-platform apps
add_subdirectory(app-cross)
