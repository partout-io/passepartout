cmake_minimum_required(VERSION 3.22)
project(Passepartout LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Copy libpassepartout and dependencies (dynamic, will be loaded at runtime)
set(JNI_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libs)
file(GLOB PASSEPARTOUT_SOS "${JNI_DIR}/${ANDROID_ABI}/lib*.so")
set(ALL_SOS ${PASSEPARTOUT_SOS} ${SWIFT_SOS})

# Native JNI wrapper
add_library(passepartout_wrapper SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/src/helpers.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/passepartout.c
)
target_include_directories(passepartout_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Link to libpassepartout and dependencies
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
target_link_libraries(passepartout_wrapper PRIVATE
    ${AUTO_LIBS}
)
