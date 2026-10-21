if(NOT WIN32)
    return()
endif()
if(NOT MSVC)
    message(FATAL_ERROR "The VPN plugin requires MSVC and the Windows SDK with C++/WinRT.")
endif()

# The executable also runs unpackaged to register the VPN plugin.
add_library(passepartout-vpnplugin SHARED
    "${CMAKE_CURRENT_LIST_DIR}/plugin.cc"
    "${CMAKE_CURRENT_LIST_DIR}/plugin.def"
)
foreach(PLUGIN_TARGET IN ITEMS passepartout-vpnplugin passepartout-tunnel)
    set_target_properties(${PLUGIN_TARGET} PROPERTIES
        CXX_STANDARD 20
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS OFF
        MSVC_RUNTIME_LIBRARY MultiThreadedDLL
        MSVC_RUNTIME_CHECKS ""
        RUNTIME_OUTPUT_DIRECTORY "${OUTPUT_DIR}"
    )
    target_compile_definitions(${PLUGIN_TARGET} PRIVATE
        NOMINMAX UNICODE _UNICODE WINRT_LEAN_AND_MEAN
        WINAPI_FAMILY=WINAPI_FAMILY_APP
    )
    target_compile_options(${PLUGIN_TARGET} PRIVATE /EHsc /permissive- /W4)
    target_link_options(${PLUGIN_TARGET} PRIVATE /APPCONTAINER)
    # Resolve CRT startup locally before Partout's Zig import library, which
    # also exports _DllMainCRTStartup and would bypass our CRT initialization.
    target_link_libraries(${PLUGIN_TARGET} PRIVATE msvcrt)
    target_link_partout(${PLUGIN_TARGET})
    target_link_libraries(${PLUGIN_TARGET} PRIVATE windowsapp runtimeobject)
endforeach()
set_target_properties(passepartout-vpnplugin PROPERTIES
    PREFIX ""
    OUTPUT_NAME "passepartout-vpnchannel"
)

string(TOLOWER "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}" PLUGIN_ARCH)
if(PLUGIN_ARCH MATCHES "^(x64|amd64)$")
    set(PLUGIN_ARCH x64)
elseif(NOT PLUGIN_ARCH STREQUAL "arm64")
    message(FATAL_ERROR "Unsupported VPN plugin architecture: ${PLUGIN_ARCH}")
endif()
# The AppContainer CRT import libraries resolve to the VCLibs framework DLLs.
get_filename_component(PLUGIN_COMPILER_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
get_filename_component(PLUGIN_STORE_LIB_DIR
    "${PLUGIN_COMPILER_DIR}/../../../lib/${PLUGIN_ARCH}/store" ABSOLUTE)
if(NOT EXISTS "${PLUGIN_STORE_LIB_DIR}/msvcrt.lib")
    message(FATAL_ERROR "MSVC AppContainer libraries are missing: ${PLUGIN_STORE_LIB_DIR}")
endif()
target_link_directories(passepartout-vpnplugin BEFORE PRIVATE "${PLUGIN_STORE_LIB_DIR}")

configure_file("${CMAKE_CURRENT_LIST_DIR}/appxmanifest.xml"
    "${CMAKE_CURRENT_BINARY_DIR}/tunnel/appxmanifest.xml" @ONLY)
# Windows requires a logo even for a background-only package.
set(PLUGIN_LOGO "${CMAKE_CURRENT_LIST_DIR}/logo.png")

add_dependencies(passepartout-tunnel passepartout-vpnplugin)
install(TARGETS passepartout-vpnplugin
    RUNTIME DESTINATION .
)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/tunnel/appxmanifest.xml"
    DESTINATION . RENAME AppxManifest.xml
)
install(FILES "${PLUGIN_LOGO}" DESTINATION . RENAME logo.png)
