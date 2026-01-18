cmake_minimum_required(VERSION 3.21)
project(Passepartout)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Include headers
include_directories(${CMAKE_SOURCE_DIR}/include)

# Library versions
set(PASSEPARTOUT_SHA1 ec6d68cd9)
set(SWIFT_VERSION 6_2)
set(JNI_DIR ${CMAKE_SOURCE_DIR}/libs)

# Partout + dependencies (dynamic, will be loaded at runtime)
file(GLOB PASSEPARTOUT_SOS "${JNI_DIR}/passepartout-${PASSEPARTOUT_SHA1}/${ANDROID_ABI}/lib*.so")
set(ALL_SOS ${PASSEPARTOUT_SOS} ${SWIFT_SOS})

foreach(SO_FILE ${ALL_SOS})
    get_filename_component(SO_NAME ${SO_FILE} NAME_WE)
    string(REPLACE "lib" "" lib ${SO_NAME})
    add_library(${lib} SHARED IMPORTED)
    set_target_properties(${lib} PROPERTIES
        IMPORTED_LOCATION ${SO_FILE}
        IMPORTED_NO_SONAME 1
    )
    list(APPEND AUTO_LIBS ${lib})
endforeach()

# Native wrappings for JNI
add_library(passepartout_wrapper SHARED src/wrapper.c)
target_link_libraries(passepartout_wrapper PRIVATE ${AUTO_LIBS})
