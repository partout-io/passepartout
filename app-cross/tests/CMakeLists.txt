cmake_minimum_required(VERSION 3.28)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
project(PassepartoutTests LANGUAGES CXX)

# Dependencies: build models and application state without the VPN core library.
set(PP_BUILD_LIBRARY OFF)
set(PP_BUILD_MODELS ON)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../../partout" partout)

include("${CMAKE_CURRENT_SOURCE_DIR}/../core.cmake")

# Portable test executables
add_executable(passepartout-models-test models.cc)
target_link_libraries(passepartout-models-test PRIVATE passepartout-models)
add_executable(passepartout-application-test application.cc)
target_link_libraries(passepartout-application-test PRIVATE passepartout-core)
add_executable(passepartout-presentation-test presentation.cc
    ../app/ui/extensions/app_profile.cc ../app/ui/extensions/data_helpers.cc)
target_link_libraries(passepartout-presentation-test PRIVATE passepartout-core)

# Keep assertions enabled in every build configuration.
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
    find_program(TEST_POWERSHELL NAMES powershell.exe REQUIRED)
    add_test(NAME passepartout-development-registration
        COMMAND "${TEST_POWERSHELL}" -NoProfile -NonInteractive -ExecutionPolicy Bypass
            -File "${CMAKE_CURRENT_SOURCE_DIR}/development-registration.ps1")
    # CTest may inherit PowerShell 7 module paths from CI. Let Windows
    # PowerShell construct its own paths instead of loading incompatible modules.
    set_tests_properties(passepartout-development-registration PROPERTIES
        ENVIRONMENT_MODIFICATION "PSModulePath=unset:")

    # Compile the adapter independently of the desktop application.
    add_library(passepartout-windows-integration-check OBJECT
        ../app/platform/windows_tunnel.cc
        ../app/platform/windows_configuration_picker.cc)
    # Match Partout::WinRTRuntime's public requirement for C++/WinRT headers.
    target_compile_features(passepartout-windows-integration-check PRIVATE cxx_std_20)
    target_link_libraries(passepartout-windows-integration-check PRIVATE
        passepartout-core Partout::Headers partout-winrt-backend)
    target_compile_options(passepartout-windows-integration-check PRIVATE /EHsc /permissive- /utf-8 /W4)
endif()
