# Keep maintained C++ filenames consistent on application and test builds.
# Domain model filenames belong to the shared code generator.
include_guard(GLOBAL)
foreach(directory IN ITEMS app tests tunnel windows)
    file(GLOB_RECURSE sources CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_LIST_DIR}/${directory}/*.cc"
        "${CMAKE_CURRENT_LIST_DIR}/${directory}/*.cpp"
        "${CMAKE_CURRENT_LIST_DIR}/${directory}/*.h"
        "${CMAKE_CURRENT_LIST_DIR}/${directory}/*.hpp"
        "${CMAKE_CURRENT_LIST_DIR}/${directory}/*.h.in")
    foreach(source IN LISTS sources)
        get_filename_component(name "${source}" NAME)
        if(NOT name MATCHES "^[A-Z][a-zA-Z0-9]*([+][A-Z][a-zA-Z0-9]*)?\\.(cc|cpp|h|hpp)(\\.in)?$")
            message(FATAL_ERROR "Use UpperCamelCase (optionally Type+Domain) for app-cross C++ filenames: ${source}")
        endif()
    endforeach()
endforeach()
