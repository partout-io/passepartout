if(NOT WIN32)
    return()
endif()

# Product and Windows package identity shared by generated artifacts.
set(PASSEPARTOUT_DISPLAY_NAME "Passepartout")
set(PASSEPARTOUT_PACKAGE_DESCRIPTION "Passepartout VPN")
set(PASSEPARTOUT_PACKAGE_NAME "Passepartout.VpnChannel")
set(PASSEPARTOUT_APPLICATION_ID "Passepartout")
set(PASSEPARTOUT_PUBLISHER_DISPLAY_NAME "Passepartout VpnChannel")
set(PASSEPARTOUT_BACKGROUND_TASK "${PASSEPARTOUT_PACKAGE_NAME}.BackgroundTask")
get_filename_component(PASSEPARTOUT_PACKAGE_LOGO "${PASSEPARTOUT_APP_ICON}" NAME)
set(PASSEPARTOUT_PACKAGE_VERSION "0.1.0.0" CACHE STRING "Four-part MSIX version (0.x for development; 1.0.0.0 reserved for production)")
set(PASSEPARTOUT_PACKAGE_PUBLISHER "CN=Passepartout VpnChannel" CACHE STRING "MSIX publisher matching the signing certificate")

if(NOT PASSEPARTOUT_PACKAGE_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$")
    message(FATAL_ERROR "PASSEPARTOUT_PACKAGE_VERSION must be a four-part numeric version")
endif()
# Escape presentation/identity strings for XML and the generated C++ header.
foreach(name IN ITEMS DISPLAY_NAME PACKAGE_DESCRIPTION PACKAGE_NAME APPLICATION_ID
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
set(PASSEPARTOUT_PLUGIN_FILE "$<TARGET_FILE_NAME:passepartout-vpnplugin>")
set(PASSEPARTOUT_TUNNEL_FILE "$<TARGET_FILE_NAME:passepartout-tunnel>")
configure_file("${CMAKE_CURRENT_LIST_DIR}/windows/package_constants.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/package_constants.h.in" @ONLY)
file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>/package_constants.h"
    INPUT "${CMAKE_CURRENT_BINARY_DIR}/package_constants.h.in")
foreach(target IN ITEMS passepartout-tunnel passepartout-vpnplugin)
    target_include_directories(${target} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>")
endforeach()
if(NOT BUILD_APP)
    return()
endif()
set(PASSEPARTOUT_FRONTEND_FILE "$<TARGET_FILE_NAME:passepartout>")
configure_file("${CMAKE_CURRENT_LIST_DIR}/windows/frontend.manifest.in"
    "${CMAKE_CURRENT_BINARY_DIR}/frontend.manifest" @ONLY)
target_sources(passepartout PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/frontend.manifest")

configure_file("${CMAKE_CURRENT_LIST_DIR}/windows/AppxManifest.xml.in"
    "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml.in" @ONLY)
file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml"
    INPUT "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml.in")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml"
    DESTINATION .
)
install(FILES "${PASSEPARTOUT_APP_ICON}" DESTINATION .)

# The packaging script validates the actual target filenames for its configuration.
file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/package-files.txt"
    CONTENT "${PASSEPARTOUT_FRONTEND_FILE}\n${PASSEPARTOUT_TUNNEL_FILE}\n${PASSEPARTOUT_PLUGIN_FILE}\n$<TARGET_FILE_NAME:Partout::Partout>\nAppxManifest.xml\n${PASSEPARTOUT_PACKAGE_LOGO}\n")
