# Shared domain, persistence, and state handling; no wxWidgets or WinRT dependency.
# Included by both the application and the standalone test project.
include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/filenames.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/files.cmake")

# Configuration
option(PASSEPARTOUT_MODEL_UNITY_BUILD "Batch generated model compilation" ON)

# Generated application models
add_library(passepartout-models STATIC ${MODEL_SOURCES})
target_compile_features(passepartout-models PUBLIC cxx_std_17)
target_include_directories(passepartout-models PUBLIC "${CMAKE_CURRENT_LIST_DIR}/models")
target_link_libraries(passepartout-models PUBLIC Partout::Models)

# Generated models repeatedly parse the same JSON and model headers. Compile
# the application models as one unit, keeping handwritten sources independent.
set_target_properties(passepartout-models PROPERTIES
    UNITY_BUILD ${PASSEPARTOUT_MODEL_UNITY_BUILD}
    UNITY_BUILD_BATCH_SIZE 0
    # These generated sources use headers, not C++20 modules.
    CXX_SCAN_FOR_MODULES OFF
)

# Shared application state and persistence
find_package(Threads REQUIRED)

# Embed the shared constants and reconfigure when their source changes.
set(APP_CONSTANTS_PATH "${CMAKE_CURRENT_LIST_DIR}/../resources/constants.json")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${APP_CONSTANTS_PATH}")
file(READ "${APP_CONSTANTS_PATH}" APP_CONSTANTS_JSON)
configure_file("${CMAKE_CURRENT_LIST_DIR}/app/context/AppConstantsResource.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/generated/AppConstantsResource.h" @ONLY)

set(APP_CREDITS_PATH "${CMAKE_CURRENT_LIST_DIR}/../resources/credits.json")
set(APP_CHANGELOG_PATH "${CMAKE_CURRENT_LIST_DIR}/CHANGELOG.txt")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${APP_CREDITS_PATH}" "${APP_CHANGELOG_PATH}")
file(READ "${APP_CREDITS_PATH}" APP_CREDITS_JSON)
file(READ "${APP_CHANGELOG_PATH}" APP_CHANGELOG)
configure_file("${CMAKE_CURRENT_LIST_DIR}/app/context/SettingsResources.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/generated/SettingsResources.h" @ONLY)

add_library(passepartout-core STATIC ${CORE_SOURCES})
target_link_libraries(passepartout-core
    PUBLIC passepartout-models Threads::Threads
    PRIVATE Partout::Headers)
target_include_directories(passepartout-core PUBLIC "${CMAKE_CURRENT_LIST_DIR}/app"
    "${CMAKE_CURRENT_BINARY_DIR}/generated")

if(MSVC)
    target_compile_options(passepartout-core PRIVATE /EHsc /permissive- /utf-8 /W4)
else()
    target_compile_options(passepartout-core PRIVATE -Wall -Wextra -Wpedantic)
endif()
