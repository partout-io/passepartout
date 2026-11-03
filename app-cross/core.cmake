# Shared domain, persistence, and state handling; no wxWidgets or WinRT dependency.
include_guard(GLOBAL)
if(NOT TARGET nlohmann_json::nlohmann_json)
    find_package(nlohmann_json CONFIG REQUIRED)
endif()
include("${CMAKE_CURRENT_LIST_DIR}/../partout/cmake/models.cmake")
file(GLOB app_model_sources CONFIGURE_DEPENDS "${CMAKE_CURRENT_LIST_DIR}/models/*.cpp")
add_library(passepartout-models STATIC ${app_model_sources})
target_compile_features(passepartout-models PUBLIC cxx_std_17)
target_include_directories(passepartout-models PUBLIC "${CMAKE_CURRENT_LIST_DIR}/models")
target_link_libraries(passepartout-models PUBLIC Partout::Models)
find_package(Threads REQUIRED)
add_library(passepartout-core STATIC
    "${CMAKE_CURRENT_LIST_DIR}/app/business/profiles.cc"
    "${CMAKE_CURRENT_LIST_DIR}/app/business/tunnel.cc"
    "${CMAKE_CURRENT_LIST_DIR}/app/observables/session.cc"
)
target_link_libraries(passepartout-core PUBLIC passepartout-models Threads::Threads)
target_include_directories(passepartout-core PUBLIC "${CMAKE_CURRENT_LIST_DIR}/app")

if(MSVC)
    target_compile_options(passepartout-core PRIVATE /EHsc /permissive- /utf-8 /W4)
else()
    target_compile_options(passepartout-core PRIVATE -Wall -Wextra -Wpedantic)
endif()
