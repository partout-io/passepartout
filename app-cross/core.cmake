# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: GPL-3.0

# Shared domain, persistence, and state handling; no wxWidgets or WinRT dependency.
include_guard(GLOBAL)
if(NOT TARGET nlohmann_json::nlohmann_json)
    find_package(nlohmann_json CONFIG REQUIRED)
endif()
include("${CMAKE_CURRENT_LIST_DIR}/../partout/cmake/models.cmake")
add_library(passepartout-models STATIC ${MODEL_SOURCES})
target_compile_features(passepartout-models PUBLIC cxx_std_17)
target_include_directories(passepartout-models PUBLIC "${CMAKE_CURRENT_LIST_DIR}/models")
target_link_libraries(passepartout-models PUBLIC Partout::Models)

# Generated models repeatedly parse the same JSON and model headers. Compile
# the application models as one unit, keeping handwritten sources independent.
option(PASSEPARTOUT_MODEL_UNITY_BUILD "Batch generated model compilation" ON)
set_target_properties(passepartout-models PROPERTIES
    UNITY_BUILD ${PASSEPARTOUT_MODEL_UNITY_BUILD}
    UNITY_BUILD_BATCH_SIZE 0
    # These generated sources use headers, not C++20 modules.
    CXX_SCAN_FOR_MODULES OFF
)

find_package(Threads REQUIRED)
set(APP_CONSTANTS_PATH "${CMAKE_CURRENT_LIST_DIR}/../app-apple/Sources/AppResources/Resources/constants.json")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${APP_CONSTANTS_PATH}")
file(READ "${APP_CONSTANTS_PATH}" APP_CONSTANTS_JSON)
configure_file("${CMAKE_CURRENT_LIST_DIR}/app/context/app_constants_resource.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/generated/app_constants_resource.h" @ONLY)
add_library(passepartout-core STATIC ${CORE_SOURCES})
target_link_libraries(passepartout-core PUBLIC passepartout-models Threads::Threads)
target_include_directories(passepartout-core PUBLIC "${CMAKE_CURRENT_LIST_DIR}/app"
    "${CMAKE_CURRENT_BINARY_DIR}/generated")

if(MSVC)
    target_compile_options(passepartout-core PRIVATE /EHsc /permissive- /utf-8 /W4)
else()
    target_compile_options(passepartout-core PRIVATE -Wall -Wextra -Wpedantic)
endif()
