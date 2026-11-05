if(NOT WIN32)
    return()
endif()

# Shared identity and assets for the desktop frontend and VPN plugin.
set(PASSEPARTOUT_PACKAGE_VERSION "0.1.0.0" CACHE STRING "Four-part MSIX version (0.x for development; 1.0.0.0 reserved for production)")
set(PASSEPARTOUT_PACKAGE_PUBLISHER "CN=Passepartout VpnChannel" CACHE STRING "MSIX publisher matching the signing certificate")
if(NOT PASSEPARTOUT_PACKAGE_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$")
    message(FATAL_ERROR "PASSEPARTOUT_PACKAGE_VERSION must be a four-part numeric version")
endif()
set(PASSEPARTOUT_PACKAGE_PUBLISHER_XML "${PASSEPARTOUT_PACKAGE_PUBLISHER}")
string(REPLACE "&" "&amp;" PASSEPARTOUT_PACKAGE_PUBLISHER_XML "${PASSEPARTOUT_PACKAGE_PUBLISHER_XML}")
string(REPLACE "<" "&lt;" PASSEPARTOUT_PACKAGE_PUBLISHER_XML "${PASSEPARTOUT_PACKAGE_PUBLISHER_XML}")
string(REPLACE "\"" "&quot;" PASSEPARTOUT_PACKAGE_PUBLISHER_XML "${PASSEPARTOUT_PACKAGE_PUBLISHER_XML}")
set(PASSEPARTOUT_FRONTEND_MANIFEST "")
set(PASSEPARTOUT_FRONTEND_CAPABILITY "")
if(BUILD_APP)
    configure_file("${CMAKE_CURRENT_LIST_DIR}/frontend.manifest.in"
        "${CMAKE_CURRENT_BINARY_DIR}/frontend.manifest" @ONLY)
    target_sources(passepartout PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/frontend.manifest")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_LIST_DIR}/frontend.xml.in")
    file(READ "${CMAKE_CURRENT_LIST_DIR}/frontend.xml.in" PASSEPARTOUT_FRONTEND_MANIFEST)
    set(PASSEPARTOUT_FRONTEND_CAPABILITY "    <rescap:Capability Name=\"runFullTrust\" />")
endif()

configure_file("${CMAKE_CURRENT_LIST_DIR}/AppxManifest.xml.in"
    "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml" @ONLY)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml"
    DESTINATION .
)
# Windows requires a logo even for a background-only package.
install(FILES "${CMAKE_CURRENT_LIST_DIR}/logo.png" DESTINATION .)
