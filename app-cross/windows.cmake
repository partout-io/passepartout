# Windows platform, executable, and package configuration.
# Both entry points are safe to call on other platforms.

# Configure the platform before Partout registers its install rules.
function(configure_windows_platform)
    if(NOT WIN32)
        return()
    endif()

    # Toolchain requirements and architecture used by the vendor libraries.
    if(NOT MSVC OR CMAKE_VERSION VERSION_LESS 4.0)
        message(FATAL_ERROR "Windows requires MSVC, the Windows SDK, and CMake 4.0 or newer")
    endif()
    string(TOLOWER "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}" PASSEPARTOUT_WINDOWS_ARCH)
    if(PASSEPARTOUT_WINDOWS_ARCH MATCHES "^(x64|amd64)$")
        set(PASSEPARTOUT_WINDOWS_ARCH x64)
    elseif(NOT PASSEPARTOUT_WINDOWS_ARCH STREQUAL "arm64")
        message(FATAL_ERROR "Unsupported Windows architecture: ${PASSEPARTOUT_WINDOWS_ARCH}")
    endif()
    set(PASSEPARTOUT_WINDOWS_ARCH "${PASSEPARTOUT_WINDOWS_ARCH}" PARENT_SCOPE)

    # Export defaults to the caller before it declares any native targets.
    if(NOT CMAKE_MSVC_RUNTIME_LIBRARY)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL" PARENT_SCOPE)
    endif()

    # AppContainer CRT libraries do not supply the desktop /RTC helpers.
    # Apply this to static dependencies too, particularly the shared models.
    set(CMAKE_MSVC_RUNTIME_CHECKS "" PARENT_SCOPE)

    # Installation prerequisites must run before Partout installs its DLLs.
    if(NOT BUILD_APP)
        install(CODE [[
            message(FATAL_ERROR "Windows installations require app and plugin. Configure with BUILD_APP=ON.")
        ]])
    endif()
endfunction()

# Configure Windows targets after the app and tunnel have been declared.
function(configure_windows_targets)
    if(NOT WIN32)
        return()
    endif()

    # Desktop executable properties and optional debug symbols.
    foreach(target IN LISTS APP_TARGETS)
        set_target_properties(${target} PROPERTIES WIN32_EXECUTABLE ON)
    endforeach()
    if(BUILD_APP)
        target_link_libraries(passepartout PRIVATE windowsapp runtimeobject)
        target_compile_definitions(passepartout PRIVATE NOMINMAX)
        target_compile_options(passepartout PRIVATE /EHsc /permissive- /utf-8)
        install(FILES "$<TARGET_PDB_FILE:passepartout>"
            DESTINATION . CONFIGURATIONS Debug RelWithDebInfo OPTIONAL
        )
    endif()

    # The host loads the plugin dynamically; only the plugin links to Partout.
    add_library(passepartout-vpnplugin SHARED
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/tunnel/windows/Plugin.cc"
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/tunnel/windows/plugin.def"
    )
    foreach(PLUGIN_TARGET IN ITEMS passepartout-vpnplugin passepartout-tunnel)
        set_target_properties(${PLUGIN_TARGET} PROPERTIES
            CXX_STANDARD 20
            CXX_STANDARD_REQUIRED ON
            CXX_EXTENSIONS OFF
            MSVC_RUNTIME_LIBRARY MultiThreadedDLL
            MSVC_RUNTIME_CHECKS ""
        )
        target_compile_definitions(${PLUGIN_TARGET} PRIVATE
            NOMINMAX UNICODE _UNICODE WINRT_LEAN_AND_MEAN
            WINAPI_FAMILY=WINAPI_FAMILY_APP
        )
        target_compile_options(${PLUGIN_TARGET} PRIVATE /EHsc /permissive- /W4)
        target_link_options(${PLUGIN_TARGET} PRIVATE /APPCONTAINER)
        target_link_libraries(${PLUGIN_TARGET} PRIVATE windowsapp runtimeobject)
    endforeach()
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/models.cmake")
    target_link_libraries(passepartout-vpnplugin PRIVATE passepartout-identity passepartout-models)
    target_link_partout_runtime(passepartout-vpnplugin)
    set_target_properties(passepartout-vpnplugin PROPERTIES
        PREFIX ""
    )

    # The AppContainer CRT import libraries resolve to the VCLibs framework DLLs.
    get_filename_component(PLUGIN_COMPILER_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
    get_filename_component(PLUGIN_STORE_LIB_DIR
        "${PLUGIN_COMPILER_DIR}/../../../lib/${PASSEPARTOUT_WINDOWS_ARCH}/store" ABSOLUTE)
    if(NOT EXISTS "${PLUGIN_STORE_LIB_DIR}/msvcrt.lib")
        message(FATAL_ERROR "MSVC AppContainer libraries are missing: ${PLUGIN_STORE_LIB_DIR}")
    endif()
    target_link_directories(passepartout-vpnplugin BEFORE PRIVATE "${PLUGIN_STORE_LIB_DIR}")

    add_dependencies(passepartout-tunnel passepartout-vpnplugin)
    install(TARGETS passepartout-vpnplugin
        RUNTIME DESTINATION .
    )

    # Package configuration and identity shared by generated artifacts.
    set(PASSEPARTOUT_NAME "Passepartout")
    set(PASSEPARTOUT_TUNNEL_NAME "${PASSEPARTOUT_NAME}Tunnel")
    set(PASSEPARTOUT_DISPLAY_NAME "${PASSEPARTOUT_NAME}")
    set(PASSEPARTOUT_PACKAGE_DESCRIPTION "${PASSEPARTOUT_NAME}")
    set(PASSEPARTOUT_PACKAGE_NAME "${PASSEPARTOUT_NAME}" CACHE STRING "MSIX package identity name")
    set(PASSEPARTOUT_APPLICATION_ID "${PASSEPARTOUT_NAME}")
    set(PASSEPARTOUT_PUBLISHER_DISPLAY_NAME "${PASSEPARTOUT_NAME}" CACHE STRING "MSIX publisher display name")
    set(PASSEPARTOUT_BACKGROUND_TASK "${PASSEPARTOUT_TUNNEL_NAME}.BackgroundTask")
    get_filename_component(PASSEPARTOUT_PACKAGE_LOGO "${PASSEPARTOUT_APP_ICON}" NAME)
    set(PASSEPARTOUT_PACKAGE_VERSION "${PASSEPARTOUT_APP_VERSION}.0" CACHE STRING "Four-part MSIX identity, independent of the application build")
    set(PASSEPARTOUT_PACKAGE_PUBLISHER "CN=${PASSEPARTOUT_PUBLISHER_DISPLAY_NAME}" CACHE STRING "MSIX publisher matching the signing certificate")

    if(NOT PASSEPARTOUT_PACKAGE_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$")
        message(FATAL_ERROR "PASSEPARTOUT_PACKAGE_VERSION must be a four-part numeric version")
    endif()
    # Escape presentation/identity strings for XML and the generated C++ header.
    foreach(name IN ITEMS DISPLAY_NAME TUNNEL_NAME PACKAGE_DESCRIPTION PACKAGE_NAME APPLICATION_ID
            PUBLISHER_DISPLAY_NAME BACKGROUND_TASK PACKAGE_LOGO PACKAGE_PUBLISHER)
        set(value "${PASSEPARTOUT_${name}}")
        string(REPLACE "&" "&amp;" value "${value}")
        string(REPLACE "<" "&lt;" value "${value}")
        string(REPLACE "\"" "&quot;" value "${value}")
        set(PASSEPARTOUT_${name}_XML "${value}")
        set(value "${PASSEPARTOUT_${name}}")
        string(REPLACE "\\" "\\\\" value "${value}")
        string(REPLACE "\"" "\\\"" value "${value}")
        set(PASSEPARTOUT_${name}_CPP "${value}")
    endforeach()

    # Generate identity headers for the host and plugin, including host-only builds.
    set(TUNNEL_CONSTANTS_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../resources/constants.json")
    if(NOT BUILD_APP)
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${TUNNEL_CONSTANTS_PATH}")
    endif()
    file(READ "${TUNNEL_CONSTANTS_PATH}" TUNNEL_CONSTANTS_JSON)
    string(JSON PASSEPARTOUT_DNS_FALLBACK_JSON GET "${TUNNEL_CONSTANTS_JSON}" tunnel dnsFallbackServers)
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/tunnel/TunnelDefaults.h.in"
        "${CMAKE_CURRENT_BINARY_DIR}/generated/TunnelDefaults.h" @ONLY)
    target_include_directories(passepartout-vpnplugin PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/generated")
    set(PASSEPARTOUT_PLUGIN_FILE "$<TARGET_FILE_NAME:passepartout-vpnplugin>")
    set(PASSEPARTOUT_TUNNEL_FILE "$<TARGET_FILE_NAME:passepartout-tunnel>")
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/windows/PackageConstants.h.in"
        "${CMAKE_CURRENT_BINARY_DIR}/PackageConstants.h.in" @ONLY)
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>/PackageConstants.h"
        INPUT "${CMAKE_CURRENT_BINARY_DIR}/PackageConstants.h.in")
    foreach(target IN ITEMS passepartout-tunnel passepartout-vpnplugin)
        target_include_directories(${target} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>")
    endforeach()
    if(NOT BUILD_APP)
        return()
    endif()

    # Full application package: desktop activation, MSIX manifest, and assets.
    set(PASSEPARTOUT_FRONTEND_FILE "$<TARGET_FILE_NAME:passepartout>")
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/windows/frontend.manifest.in"
        "${CMAKE_CURRENT_BINARY_DIR}/frontend.manifest" @ONLY)
    target_sources(passepartout PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/frontend.manifest")

    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/windows/AppxManifest.xml.in"
        "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml.in" @ONLY)
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml"
        INPUT "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml.in")
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml"
        DESTINATION .
    )
    install(FILES "${PASSEPARTOUT_APP_ICON}" DESTINATION .)

endfunction()
