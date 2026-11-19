cmake_minimum_required(VERSION 3.28)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
project(PassepartoutTests LANGUAGES CXX)

# Dependencies: build models and application state without the VPN core library.
set(PP_BUILD_LIBRARY OFF)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../../partout" partout)

include("${CMAKE_CURRENT_SOURCE_DIR}/../core.cmake")

# Portable test executables
add_executable(passepartout-models-test Models.cc)
target_link_libraries(passepartout-models-test PRIVATE passepartout-models)
add_executable(passepartout-application-test Application.cc)
target_link_libraries(passepartout-application-test PRIVATE passepartout-core)
add_executable(passepartout-editor-test Editor.cc)
target_link_libraries(passepartout-editor-test PRIVATE passepartout-core)
add_executable(passepartout-settings-test Settings.cc)
target_link_libraries(passepartout-settings-test PRIVATE passepartout-core)
add_executable(passepartout-activation-test Activation.cc)
target_link_libraries(passepartout-activation-test PRIVATE passepartout-core)
add_executable(passepartout-presentation-test Presentation.cc
    ../app/ui/extensions/AppProfile.cc ../app/ui/extensions/DataHelpers.cc)
target_link_libraries(passepartout-presentation-test PRIVATE passepartout-core)

# Keep assertions enabled in every build configuration.
enable_testing()
foreach(TEST_NAME IN ITEMS models application presentation editor settings activation)
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
        ../app/business/platform/WindowsTunnel.cc
        ../app/ui/platform/WindowsConfigurationPicker.cc
        ../app/ui/platform/WindowsFileActivation.cc
        ../app/business/platform/WindowsHttpClient.cc
        ../app/ui/platform/WindowsURLLauncher.cc
        ../app/ui/platform/WindowsIssueHandoff.cc)
    # Match Partout::WindowsRuntime's public requirement for C++/WinRT headers.
    target_compile_features(passepartout-windows-integration-check PRIVATE cxx_std_20)
    target_include_directories(passepartout-windows-integration-check PRIVATE
        ../../partout/cross/windows/include ../../partout/src)
    target_link_libraries(passepartout-windows-integration-check PRIVATE passepartout-core windowsapp)
    target_compile_options(passepartout-windows-integration-check PRIVATE /EHsc /permissive- /utf-8 /W4)

    # Native settings translation constructs WinRT values without starting a VPN.
    add_executable(passepartout-windows-settings-test ../../partout/tests/c/windows/tun_settings.cc)
    target_link_libraries(passepartout-windows-settings-test PRIVATE partout-windows-backend nlohmann_json::nlohmann_json)
    target_compile_features(passepartout-windows-settings-test PRIVATE cxx_std_20)
    target_compile_options(passepartout-windows-settings-test PRIVATE /UNDEBUG /utf-8 /EHsc /permissive-)
    add_test(NAME passepartout-windows-settings COMMAND passepartout-windows-settings-test)

    add_executable(passepartout-windows-credentials-test
        ../../partout/tests/c/windows/interactive_credentials.cc
        ../../partout/cross/windows/src/interactive_credentials.cc)
    target_link_libraries(passepartout-windows-credentials-test PRIVATE Partout::Models windowsapp)
    target_compile_features(passepartout-windows-credentials-test PRIVATE cxx_std_20)
    target_compile_options(passepartout-windows-credentials-test PRIVATE /UNDEBUG /utf-8 /EHsc /permissive-)
    add_test(NAME passepartout-windows-credentials COMMAND passepartout-windows-credentials-test)
endif()
