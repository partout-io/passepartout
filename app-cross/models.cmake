# Generated contracts shared by the desktop app and tunnel plugin.
include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/files.cmake")

# Configuration
option(PASSEPARTOUT_MODEL_UNITY_BUILD "Batch generated model compilation" ON)

# Generated application models
add_library(passepartout-models STATIC ${MODEL_SOURCES})
target_compile_features(passepartout-models PUBLIC cxx_std_17)
target_include_directories(passepartout-models PUBLIC "${CMAKE_CURRENT_LIST_DIR}/models")
target_link_libraries(passepartout-models PUBLIC Partout::Partout)
target_precompile_headers(passepartout-models PRIVATE <partout/Json.h>)

# Generated models repeatedly parse the same JSON and model headers. Compile
# in batches, using the same default batch size as the Partout C++ runtime.
set_target_properties(passepartout-models PROPERTIES
    UNITY_BUILD ${PASSEPARTOUT_MODEL_UNITY_BUILD}
    # These generated sources use headers, not C++20 modules.
    CXX_SCAN_FOR_MODULES OFF
)

