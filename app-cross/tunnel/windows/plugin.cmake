if(NOT WIN32)
    return()
endif()

# The host loads the plugin dynamically; only the plugin links to Partout.
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
    )
    target_compile_definitions(${PLUGIN_TARGET} PRIVATE
        NOMINMAX UNICODE _UNICODE WINRT_LEAN_AND_MEAN
        WINAPI_FAMILY=WINAPI_FAMILY_APP
    )
    target_compile_options(${PLUGIN_TARGET} PRIVATE /EHsc /permissive- /W4)
    target_link_options(${PLUGIN_TARGET} PRIVATE /APPCONTAINER)
    target_link_libraries(${PLUGIN_TARGET} PRIVATE windowsapp runtimeobject)
endforeach()
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
