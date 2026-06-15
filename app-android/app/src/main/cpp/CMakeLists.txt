cmake_minimum_required(VERSION 3.28)
project(Passepartout)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

set(PARTOUT_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../partout)

# Define NDK toolchain environment
set(ENV_ANDROID
    SWIFT_ANDROID_ABI=${ANDROID_ABI}
    SWIFT_ANDROID_ARCH=aarch64
    SWIFT_ANDROID_API_LEVEL=28
    SWIFT_ANDROID_VERSION=6.3.1
)

# Build Partout dependency with given environment
include(ExternalProject)
set(JNI_LIBS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI})
set(LIBPARTOUT_OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(LIBPARTOUT_INCLUDE ${PARTOUT_ROOT}/Sources/Partout_C/include)
set(LIBPARTOUT_SOS
    ${LIBPARTOUT_OUTPUT}/openssl/lib/libcrypto.so
    ${LIBPARTOUT_OUTPUT}/partout/libpartout.so
    ${LIBPARTOUT_OUTPUT}/openssl/lib/libssl.so
    ${LIBPARTOUT_OUTPUT}/wg-go/lib/libwg-go.so
)
set(LIBPARTOUT_NDK_TRIPLE aarch64-linux-android)
set(LIBPARTOUT_CXX_SHARED_SO ${ANDROID_TOOLCHAIN_ROOT}/sysroot/usr/lib/${LIBPARTOUT_NDK_TRIPLE}/libc++_shared.so)
ExternalProject_Add(libpartout
    SOURCE_DIR ${PARTOUT_ROOT}
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env ${ENV_ANDROID}
        ${CMAKE_COMMAND}
        -G Ninja
        -DCMAKE_TOOLCHAIN_FILE=${PARTOUT_ROOT}/toolchains/android.toolchain.cmake
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DPP_BUILD_OUTPUT=${LIBPARTOUT_OUTPUT}
        -DPP_BUILD_LIBRARY=ON
        -DPP_BUILD_USE_OPENSSL=ON
        -DPP_BUILD_USE_OPENVPN=ON
        -DPP_BUILD_USE_WIREGUARD=ON
        -S <SOURCE_DIR>
        -B <BINARY_DIR>
    BUILD_COMMAND ${CMAKE_COMMAND} -E env ${ENV_ANDROID}
        ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${JNI_LIBS_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${LIBPARTOUT_SOS}
            ${LIBPARTOUT_CXX_SHARED_SO}
            ${JNI_LIBS_DIR}
    BUILD_ALWAYS TRUE
    BUILD_BYPRODUCTS
        ${LIBPARTOUT_SOS}
)

# Native wrapper for JNI (.so)
add_library(passepartout_wrapper SHARED
        ${CMAKE_CURRENT_SOURCE_DIR}/src/wrapper.c
        ${CMAKE_CURRENT_SOURCE_DIR}/src/helpers.c
)
add_dependencies(passepartout_wrapper libpartout)
target_include_directories(passepartout_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${LIBPARTOUT_INCLUDE}
)

# Import libpartout and deps
foreach(SO_FILE IN LISTS LIBPARTOUT_SOS)
    get_filename_component(SO_NAME ${SO_FILE} NAME_WE)
    string(REGEX REPLACE "^lib" "" LIB_NAME ${SO_NAME})
    string(MAKE_C_IDENTIFIER ${LIB_NAME} LIB_TARGET_SUFFIX)
    set(LIB_TARGET libpartout_${LIB_TARGET_SUFFIX})
    add_library(${LIB_TARGET} SHARED IMPORTED)
    set_target_properties(${LIB_TARGET} PROPERTIES
        IMPORTED_LOCATION ${SO_FILE}
        IMPORTED_NO_SONAME 1
    )
    list(APPEND LIBPARTOUT_IMPORTED_LIBS ${LIB_TARGET})
endforeach()
target_link_libraries(passepartout_wrapper PRIVATE
    ${LIBPARTOUT_IMPORTED_LIBS}
)
