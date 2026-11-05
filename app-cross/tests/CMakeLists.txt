cmake_minimum_required(VERSION 3.28)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
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
add_executable(passepartout-application-test application.cc)
target_link_libraries(passepartout-application-test PRIVATE passepartout-core)
add_executable(passepartout-presentation-test presentation.cc
    ../app/ui/extensions/app_profile.cc ../app/ui/extensions/data_helpers.cc)
target_link_libraries(passepartout-presentation-test PRIVATE passepartout-core)

enable_testing()
foreach(TEST_NAME IN ITEMS models application presentation)
    set(TEST_TARGET passepartout-${TEST_NAME}-test)
    if(MSVC)
        target_compile_options(${TEST_TARGET} PRIVATE /UNDEBUG /utf-8)
    else()
        target_compile_options(${TEST_TARGET} PRIVATE -UNDEBUG)
    endif()
    add_test(NAME passepartout-${TEST_NAME} COMMAND ${TEST_TARGET})
endforeach()

# Compile the native adapter on Windows without requiring wxWidgets or a VPN.
if(WIN32)
    add_library(passepartout-windows-integration-check OBJECT ../app/platform/windows_tunnel.cc)
    # Match Partout::WindowsRuntime's public requirement for C++/WinRT headers.
    target_compile_features(passepartout-windows-integration-check PRIVATE cxx_std_20)
    target_include_directories(passepartout-windows-integration-check PRIVATE
        ../../partout/cross/windows/include ../../partout/src)
    target_link_libraries(passepartout-windows-integration-check PRIVATE passepartout-core windowsapp)
    target_compile_options(passepartout-windows-integration-check PRIVATE /EHsc /permissive- /utf-8 /W4)
endif()
