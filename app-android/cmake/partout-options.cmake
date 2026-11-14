# Application defaults; explicit CMake cache arguments take precedence.
include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/prebuilts.cmake")
set(PP_BUILD_USE_OPENVPN ON CACHE BOOL "Enable OpenVPN")
set(PP_BUILD_USE_WIREGUARD ON CACHE BOOL "Enable WireGuard")
set(PP_BUILD_USE_MBEDTLS ON CACHE BOOL "Enable MbedTLS")
set(PP_BUILD_USE_OPENSSL OFF CACHE BOOL "Enable OpenSSL")
set(PP_BUILD_VENDOR_PREBUILT_URL "${PASSEPARTOUT_PREBUILTS_URL}" CACHE STRING "Vendor archives")
