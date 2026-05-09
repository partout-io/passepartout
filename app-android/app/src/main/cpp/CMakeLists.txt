cmake_minimum_required(VERSION 3.28)
project(Passepartout)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../../../..)

# Define NDK toolchain environment
set(ENV_ANDROID
    SWIFT_ANDROID_ABI=${ANDROID_ABI}
    SWIFT_ANDROID_ARCH=aarch64
    SWIFT_ANDROID_API_LEVEL=28
    SWIFT_ANDROID_VERSION=6.3.1
)

# Build app-cross dependency with given environment
include(ExternalProject)
set(LIBPASSEPARTOUT_DIST ${CMAKE_CURRENT_SOURCE_DIR}/bin/dist)
set(LIBPASSEPARTOUT_INCLUDE ${PROJECT_ROOT}/app-cross/Sources/CommonLibrary_C/include)
set(LIBPASSEPARTOUT_SOS
    ${LIBPASSEPARTOUT_DIST}/libcrypto.so
    ${LIBPASSEPARTOUT_DIST}/libpassepartout.so
    ${LIBPASSEPARTOUT_DIST}/libssl.so
    ${LIBPASSEPARTOUT_DIST}/libwg-go.so
)
set(LIBPASSEPARTOUT_NDK_TRIPLE aarch64-linux-android)
set(LIBPASSEPARTOUT_CXX_SHARED_SO ${ANDROID_TOOLCHAIN_ROOT}/sysroot/usr/lib/${LIBPASSEPARTOUT_NDK_TRIPLE}/libc++_shared.so)
set(LIBPASSEPARTOUT_JNI_SOS
    ${LIBPASSEPARTOUT_SOS}
    ${LIBPASSEPARTOUT_CXX_SHARED_SO}
)
ExternalProject_Add(libpassepartout
    SOURCE_DIR ${PROJECT_ROOT}
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env ${ENV_ANDROID}
        ${CMAKE_COMMAND}
        -G Ninja
        -DCMAKE_TOOLCHAIN_FILE=${PROJECT_ROOT}/app-cross/partout/toolchains/android.toolchain.cmake
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DOUTPUT_DIR=${CMAKE_CURRENT_SOURCE_DIR}/bin
        -DDIST_DIR=${LIBPASSEPARTOUT_DIST}
        -S <SOURCE_DIR>
        -B <BINARY_DIR>
    BUILD_COMMAND ${CMAKE_COMMAND} -E env ${ENV_ANDROID}
        ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND ""
    BUILD_ALWAYS TRUE
    BUILD_BYPRODUCTS
        ${LIBPASSEPARTOUT_SOS}
)

# Native wrapper for JNI (.so)
add_library(passepartout_wrapper SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/src/passepartout.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/helpers.c
)
add_dependencies(passepartout_wrapper libpassepartout)
target_include_directories(passepartout_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${LIBPASSEPARTOUT_INCLUDE}
    ${LIBPASSEPARTOUT_DIST}
)

# Import libpassepartout and deps
foreach(SO_FILE IN LISTS LIBPASSEPARTOUT_SOS)
    get_filename_component(SO_NAME ${SO_FILE} NAME_WE)
    string(REGEX REPLACE "^lib" "" LIB_NAME ${SO_NAME})
    string(MAKE_C_IDENTIFIER ${LIB_NAME} LIB_TARGET_SUFFIX)
    set(LIB_TARGET libpassepartout_${LIB_TARGET_SUFFIX})
    add_library(${LIB_TARGET} SHARED IMPORTED)
    set_target_properties(${LIB_TARGET} PROPERTIES
        IMPORTED_LOCATION ${SO_FILE}
        IMPORTED_NO_SONAME 1
    )
    list(APPEND LIBPASSEPARTOUT_IMPORTED_LIBS ${LIB_TARGET})
endforeach()
target_link_libraries(passepartout_wrapper PRIVATE
    ${LIBPASSEPARTOUT_IMPORTED_LIBS}
)

# Distribute as JNI libs
set(JNI_LIBS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI})
add_custom_command(
    TARGET passepartout_wrapper
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${JNI_LIBS_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${LIBPASSEPARTOUT_JNI_SOS}
        ${JNI_LIBS_DIR}
    COMMENT "Copying app-cross shared libraries to jniLibs"
)
