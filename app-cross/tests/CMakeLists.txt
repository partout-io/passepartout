cmake_minimum_required(VERSION 3.28)
if(POLICY CMP0184)
    cmake_policy(SET CMP0184 NEW)
endif()
set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
set(CMAKE_MSVC_RUNTIME_CHECKS "")
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
project(PassepartoutTests LANGUAGES CXX)

# Dependencies: link application tests against the shared Partout library.
set(PP_BUILD_LIBRARY ON)
if(WIN32)
    set(PP_BUILD_WINRT ON)
endif()
set(PP_TEST_CPP_RUNTIME OFF)
set(PP_TEST_WINRT_RUNTIME OFF)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../../partout" partout)

include("${CMAKE_CURRENT_SOURCE_DIR}/../core.cmake")

# Keep generated C++ warning-clean in the standalone regression build.
if(MSVC)
    target_compile_options(passepartout-models PRIVATE /WX)
endif()

# Test executables
add_executable(passepartout-models-test Models.cc)
target_link_libraries(passepartout-models-test PRIVATE passepartout-models)
add_executable(passepartout-application-test Application.cc ObservableFixture.cc)
target_link_libraries(passepartout-application-test PRIVATE passepartout-core)
add_executable(passepartout-editor-test Editor.cc ObservableFixture.cc)
target_link_libraries(passepartout-editor-test PRIVATE passepartout-core)
add_executable(passepartout-settings-test Settings.cc)
target_link_libraries(passepartout-settings-test PRIVATE passepartout-core)
add_executable(passepartout-activation-test Activation.cc)
target_link_libraries(passepartout-activation-test PRIVATE passepartout-core)

# UI implementation tests require the frontend toolkit and are excluded here.

# Keep assertions enabled in every build configuration.
enable_testing()
foreach(TEST_NAME IN ITEMS models application editor settings activation)
    set(TEST_TARGET passepartout-${TEST_NAME}-test)
    if(MSVC)
        target_compile_options(${TEST_TARGET} PRIVATE /utf-8
            "/FI${CMAKE_CURRENT_LIST_DIR}/Support.h")
    else()
        target_compile_options(${TEST_TARGET} PRIVATE -UNDEBUG)
    endif()
    if(WIN32)
        add_custom_command(TARGET ${TEST_TARGET} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_RUNTIME_DLLS:${TEST_TARGET}> $<TARGET_FILE_DIR:${TEST_TARGET}>
            COMMAND_EXPAND_LISTS)
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

    # Compile adapters without wxWidgets independently of the desktop application.
    # WindowsURLLauncher owns a wxWindow and is compiled with the application.
    add_library(passepartout-windows-integration-check OBJECT
        ../app/business/platform/WindowsPreferencesRepository.cc
        ../app/ui/platform/WindowsConfigurationPicker.cc
        ../app/ui/platform/FileActivation.cc
        ../app/business/platform/WindowsHttpClient.cc
        ../app/ui/platform/WindowsIssueHandoff.cc)
    target_link_libraries(passepartout-windows-integration-check PRIVATE
        passepartout-core Partout::Headers)
    target_compile_features(passepartout-windows-integration-check PRIVATE cxx_std_20)
    target_compile_options(passepartout-windows-integration-check PRIVATE /EHsc /permissive- /utf-8 /W4)
endif()
