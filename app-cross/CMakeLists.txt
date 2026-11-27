cmake_minimum_required(VERSION 3.28)

# CMake policies
# Select per-target MSVC runtime checks before enabling any languages.
if(POLICY CMP0184)
    cmake_policy(SET CMP0184 NEW)
endif()

# Normalize installation destinations in this project and its dependencies.
if(POLICY CMP0177)
    cmake_policy(SET CMP0177 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0177 NEW)
endif()
project(Passepartout LANGUAGES C CXX)
include("core.cmake")

# No target uses C++ modules, including the C++20 WinRT bridge. Avoid
# unnecessary dyndep scanning, which can assert in Ninja on rebuilds.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

# Application options and output layout
option(BUILD_APP "Build app executable" OFF)
set(PASSEPARTOUT_APP_ICON "${CMAKE_CURRENT_SOURCE_DIR}/logo.png")

if(NOT OUTPUT_DIR)
    set(OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
endif()

# Install shared runtimes beside the app and tunnel executables.
set(CMAKE_INSTALL_BINDIR ".")
set(CMAKE_INSTALL_LIBDIR ".")

# Dependency archive defaults; caller-supplied locations take precedence.
include("${CMAKE_CURRENT_SOURCE_DIR}/../cmake/prebuilts.cmake")
if(NOT PP_BUILD_VENDOR_PREBUILT_URL)
    set(PP_BUILD_VENDOR_PREBUILT_URL "${PASSEPARTOUT_PREBUILTS_URL}")
endif()
if(NOT PASSEPARTOUT_WX_PREBUILT_BASE_URL)
    set(PASSEPARTOUT_WX_PREBUILT_BASE_URL "${PASSEPARTOUT_PREBUILTS_URL}")
endif()

# Partout configuration
if(WIN32)
    set(PP_BUILD_WINRT ON)
endif()
set(PP_BUILD_OUTPUT "${OUTPUT_DIR}")
set(PP_BUILD_USE_OPENSSL ON)
set(PP_BUILD_USE_MBEDTLS ON)
if(UNIX AND NOT APPLE AND NOT ANDROID)
    set(PP_BUILD_USE_MBEDTLS OFF)
endif()
set(PP_BUILD_USE_OPENVPN ON)
set(PP_BUILD_USE_WIREGUARD ON)

# Set the Windows toolchain defaults and register the stop-host install hook
# before Partout registers installation of its shared libraries.
include("windows.cmake")
configure_windows_platform()

add_subdirectory(../partout partout)

# App and plugin runtime outputs share the selected directory.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${OUTPUT_DIR}")

# Runtime linkage shared by the app, POSIX tunnel, and Windows plugin.
# The Windows tunnel host loads its plugin without linking Partout directly.
function(target_link_partout_runtime target)
    target_link_libraries(${target} PRIVATE Partout::Partout)
    if(LINUX)
        target_link_options(${target} PRIVATE
            "LINKER:-rpath-link,${PP_BUILD_OUTPUT}/wg-go/lib"
        )
    endif()
endfunction()

# Desktop application (optional)
if(BUILD_APP)
    configure_application_core()
    add_executable(passepartout ${APP_SOURCES})
    target_link_partout_runtime(passepartout)
    target_link_libraries(passepartout PRIVATE passepartout-core)

    # Embed the package logo so desktop icons do not depend on runtime file paths.
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${PASSEPARTOUT_APP_ICON}")
    file(READ "${PASSEPARTOUT_APP_ICON}" APP_ICON_HEX HEX)
    string(REGEX REPLACE "(..)" "0x\\1," APP_ICON_BYTES "${APP_ICON_HEX}")
    configure_file("${CMAKE_CURRENT_LIST_DIR}/app/ui/theme/AppIconResource.h.in"
        "${CMAKE_CURRENT_BINARY_DIR}/generated/AppIconResource.h" @ONLY)

    # Load wxWidgets only for the desktop application.
    include("wx.cmake")
    target_precompile_headers(passepartout PRIVATE <wx/wx.h> <partout/Json.h>)

    option(BUILD_UI_TESTS "Build native wxWidgets presentation regression tests" OFF)
    if(BUILD_UI_TESTS)
        add_executable(passepartout-ui-test
            tests/ThemeDetails.cc app/ui/settings/SettingsView.cc app/ui/diagnostics/IssueReportView.cc
            app/ui/profile/ModuleDetailView.cc app/ui/profile/modules/DNSView.cc
            app/ui/profile/modules/IPView.cc app/ui/profile/modules/HTTPProxyView.cc
            app/ui/profile/modules/OpenVPNView.cc app/ui/profile/modules/WireGuardView.cc
            app/ui/theme/Theme.cc app/ui/theme/ThemeList.cc
            app/ui/theme/ThemeDetailView.cc app/ui/theme/ThemeLongContent.cc
            app/ui/theme/ThemeButtonRow.cc app/ui/theme/ThemeModal.cc
            app/ui/theme/ThemeContentLink.cc app/strings/Strings.cc)
        target_compile_features(passepartout-ui-test PRIVATE cxx_std_17)
        target_link_libraries(passepartout-ui-test PRIVATE passepartout-identity Partout::Partout)
        if(MSVC)
            target_compile_options(passepartout-ui-test PRIVATE /utf-8)
        endif()
        target_include_directories(passepartout-ui-test PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/generated")
        if(WIN32)
            target_link_windows_wxwidgets(passepartout-ui-test)
        else()
            target_link_system_wxwidgets(passepartout-ui-test)
        endif()
        enable_testing()
        add_test(NAME passepartout-ui COMMAND passepartout-ui-test)
    endif()


    if(APPLE)
        set_target_properties(passepartout PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_BUNDLE_NAME "Passepartout"
            MACOSX_BUNDLE_GUI_IDENTIFIER "io.partout.passepartout.cross"
        )
    endif()

    install(TARGETS passepartout
        RUNTIME DESTINATION .
        BUNDLE DESTINATION .
    )
    if(APPLE)
        # Bundle the installed Partout runtime and wxWidgets dependencies.
        install(CODE [[
            include(BundleUtilities)
            fixup_bundle("${CMAKE_INSTALL_PREFIX}/passepartout.app" ""
                "${CMAKE_INSTALL_PREFIX};$<TARGET_PROPERTY:wxWidgets::wxWidgets,INTERFACE_LINK_DIRECTORIES>")
        ]])
    endif()
endif()

# Tunnel executable (always built)
add_executable(passepartout-tunnel "")
if(WIN32)
    target_sources(passepartout-tunnel PRIVATE tunnel/windows/Main.cc)
    option(PASSEPARTOUT_WAIT_FOR_DEBUGGER "Wait up to 30 seconds for a debugger before VPN plugin initialization (Debug only)" OFF)
    if(PASSEPARTOUT_WAIT_FOR_DEBUGGER)
        target_compile_definitions(passepartout-tunnel PRIVATE $<$<CONFIG:Debug>:PASSEPARTOUT_WAIT_FOR_DEBUGGER>)
    endif()
else()
    target_sources(passepartout-tunnel PRIVATE tunnel/posix/main.c tunnel/posix/common.c)
    target_link_partout_runtime(passepartout-tunnel)
endif()

# Native executable properties
# Windows properties are applied by configure_windows_targets below.
set(APP_TARGETS passepartout-tunnel)
if(BUILD_APP)
    list(APPEND APP_TARGETS passepartout)
endif()
foreach(APP_TARGET IN LISTS APP_TARGETS)
    if(APPLE)
        set_target_properties(${APP_TARGET} PROPERTIES
            MACOSX_RPATH ON
            BUILD_WITH_INSTALL_RPATH TRUE
            INSTALL_RPATH "@loader_path"
            INSTALL_NAME_DIR "@rpath"
        )
    elseif(LINUX)
        set_target_properties(${APP_TARGET} PROPERTIES
            BUILD_RPATH "$ORIGIN"
            INSTALL_RPATH "$ORIGIN"
            SKIP_BUILD_RPATH OFF
        )
    endif()
endforeach()
install(TARGETS passepartout-tunnel
    RUNTIME DESTINATION .
)

# Windows plugin and package; configure after declaring the enabled executables.
configure_windows_targets()
