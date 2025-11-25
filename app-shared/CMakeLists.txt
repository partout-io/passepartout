cmake_minimum_required(VERSION 3.27)
project(PassepartoutShared LANGUAGES Swift)

# Include CommonLibrary sources
file(GLOB_RECURSE PSP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Sources/*.swift)
set(PSP_EXCLUSIONS
    ".*CommonLibraryApple"
    ".*CommonProvidersAPI/REST/API\\+Bundle\\.swift"
)
foreach(pattern ${PSP_EXCLUSIONS})
    list(FILTER PSP_SOURCES EXCLUDE REGEX ${pattern})
endforeach()

# Configure as static library except on Android
if(ANDROID)
    add_library(passepartout_shared SHARED ${PSP_SOURCES})
else()
    add_library(passepartout_shared STATIC ${PSP_SOURCES})
endif()
target_compile_options(passepartout_shared PRIVATE
    -DPSP_DYNLIB
)
set_target_properties(passepartout_shared PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR}
)

# XXX: C modulemaps are required to import Partout as a Swift module
set(PARTOUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../submodules/partout/Sources)
target_include_directories(passepartout_shared PRIVATE
    ${OUTPUT_DIR}/partout/modules
    ${PARTOUT_DIR}/PartoutABI_C/include
    ${PARTOUT_DIR}/PartoutCore_C/include
    ${PARTOUT_DIR}/PartoutOpenVPN_C/include
    ${PARTOUT_DIR}/PartoutWireGuard_C/include
)
target_link_directories(passepartout_shared PRIVATE
    ${OUTPUT_DIR}/partout
)
