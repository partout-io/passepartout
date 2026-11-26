# Shared application identity and portable core setup.
include_guard(GLOBAL)
# App version and shared builds/<build> identity are independent of MSIX revisions.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_LIST_DIR}/version.txt" "${CMAKE_CURRENT_LIST_DIR}/build.txt")
file(READ "${CMAKE_CURRENT_LIST_DIR}/version.txt" PASSEPARTOUT_APP_VERSION)
file(READ "${CMAKE_CURRENT_LIST_DIR}/build.txt" PASSEPARTOUT_APP_BUILD)
string(STRIP "${PASSEPARTOUT_APP_VERSION}" PASSEPARTOUT_APP_VERSION)
string(STRIP "${PASSEPARTOUT_APP_BUILD}" PASSEPARTOUT_APP_BUILD)
if(NOT PASSEPARTOUT_APP_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
    message(FATAL_ERROR "App version must contain three numeric components")
endif()
if(NOT PASSEPARTOUT_APP_BUILD MATCHES "^[1-9][0-9]*$" OR PASSEPARTOUT_APP_BUILD GREATER 2147483647)
    message(FATAL_ERROR "App build must be a positive 32-bit integer")
endif()

function(configure_application_core)
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/filenames.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/files.cmake")

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/models.cmake")

    # Shared application state and persistence
    find_package(Threads REQUIRED)

    # Embed the shared constants and reconfigure when their source changes.
    set(APP_CONSTANTS_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../resources/constants.json")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${APP_CONSTANTS_PATH}")
    file(READ "${APP_CONSTANTS_PATH}" APP_CONSTANTS_JSON)
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/app/context/AppConstantsResource.h.in"
        "${CMAKE_CURRENT_BINARY_DIR}/generated/AppConstantsResource.h" @ONLY)

    set(APP_CREDITS_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../resources/credits.json")
    set(APP_CHANGELOG_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CHANGELOG.txt")
    set(APP_ISSUE_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../resources/issue.txt")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${APP_CREDITS_PATH}" "${APP_CHANGELOG_PATH}" "${APP_ISSUE_PATH}")
    file(READ "${APP_CREDITS_PATH}" APP_CREDITS_JSON)
    file(READ "${APP_CHANGELOG_PATH}" APP_CHANGELOG)
    file(READ "${APP_ISSUE_PATH}" APP_ISSUE_TEMPLATE)
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/app/context/SettingsResources.h.in"
        "${CMAKE_CURRENT_BINARY_DIR}/generated/SettingsResources.h" @ONLY)

    add_library(passepartout-core STATIC ${CORE_SOURCES})
    target_compile_definitions(passepartout-core PUBLIC
        PASSEPARTOUT_APP_VERSION="${PASSEPARTOUT_APP_VERSION}"
        PASSEPARTOUT_APP_BUILD=${PASSEPARTOUT_APP_BUILD})
    target_link_libraries(passepartout-core
        PUBLIC passepartout-models Partout::Partout Threads::Threads
        PRIVATE Partout::Headers)
    target_include_directories(passepartout-core PUBLIC "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/app"
        "${CMAKE_CURRENT_BINARY_DIR}/generated")

    if(MSVC)
        target_compile_options(passepartout-core PRIVATE /EHsc /permissive- /utf-8 /W4)
    else()
        target_compile_options(passepartout-core PRIVATE -Wall -Wextra -Wpedantic)
    endif()
    set(APP_SOURCES "${APP_SOURCES}" PARENT_SCOPE)
endfunction()
