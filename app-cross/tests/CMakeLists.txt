cmake_minimum_required(VERSION 3.28)
project(PassepartoutTests LANGUAGES CXX)

find_package(nlohmann_json CONFIG QUIET)
if(NOT TARGET nlohmann_json::nlohmann_json)
    include(FetchContent)
    FetchContent_Declare(json
        URL https://github.com/nlohmann/json/releases/download/v3.12.0/json.tar.xz
        URL_HASH SHA256=42f6e95cad6ec532fd372391373363b62a14af6d771056dbfc86160e6dfff7aa
    )
    FetchContent_MakeAvailable(json)
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/../files.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/../core.cmake")

add_executable(passepartout-models-test models.cc)
target_link_libraries(passepartout-models-test PRIVATE passepartout-models)
if(MSVC)
    target_compile_options(passepartout-models-test PRIVATE /UNDEBUG)
else()
    target_compile_options(passepartout-models-test PRIVATE -UNDEBUG)
endif()
enable_testing()
add_test(NAME passepartout-models COMMAND passepartout-models-test)

add_executable(passepartout-application-test application.cc)
target_link_libraries(passepartout-application-test PRIVATE passepartout-core)
if(MSVC)
    target_compile_options(passepartout-application-test PRIVATE /UNDEBUG)
else()
    target_compile_options(passepartout-application-test PRIVATE -UNDEBUG)
endif()
add_test(NAME passepartout-application COMMAND passepartout-application-test)

# Compile the native adapter on Windows without requiring wxWidgets or a VPN.
if(WIN32)
    add_library(passepartout-windows-integration-check OBJECT ../app/platform/windows_tunnel.cc)
    target_link_libraries(passepartout-windows-integration-check PRIVATE passepartout-core windowsapp)
    target_compile_options(passepartout-windows-integration-check PRIVATE /EHsc /permissive- /utf-8 /W4)
    target_compile_options(passepartout-application-test PRIVATE /utf-8)
endif()
