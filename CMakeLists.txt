cmake_minimum_required(VERSION 3.22)
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

# Build Passepartout cross-platform app and library
add_subdirectory(app-cross)
