set(PASSEPARTOUT_PREBUILTS_VERSION "" CACHE STRING
    "Override the partout-io/prebuilts release version")
if(PASSEPARTOUT_PREBUILTS_VERSION)
    set(_PASSEPARTOUT_PREBUILTS_VERSION
        "${PASSEPARTOUT_PREBUILTS_VERSION}")
else()
    file(STRINGS "${CMAKE_CURRENT_LIST_DIR}/../prebuilts-version.txt"
        _PASSEPARTOUT_PREBUILTS_VERSION LIMIT_COUNT 1)
endif()
if(NOT _PASSEPARTOUT_PREBUILTS_VERSION MATCHES
   "^[0-9A-Za-z][0-9A-Za-z._+-]*$")
    message(FATAL_ERROR
        "Invalid Passepartout prebuilts version: '${_PASSEPARTOUT_PREBUILTS_VERSION}'")
endif()

set(PASSEPARTOUT_PREBUILTS_URL
    "https://github.com/partout-io/prebuilts/releases/download/${_PASSEPARTOUT_PREBUILTS_VERSION}")
