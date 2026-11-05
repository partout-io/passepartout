set(PASSEPARTOUT_WX_PREBUILT_DIR "" CACHE PATH "Path to an extracted wxWidgets Windows prebuilt.")
set(PASSEPARTOUT_WX_PREBUILT_BASE_URL "" CACHE STRING
    "Base URL for wxWidgets Windows prebuilts.")

# Embed the package logo so desktop icons do not depend on runtime file paths.
set(APP_ICON_PATH "${CMAKE_CURRENT_LIST_DIR}/logo.png")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${APP_ICON_PATH}")
file(READ "${APP_ICON_PATH}" APP_ICON_HEX HEX)
string(REGEX REPLACE "(..)" "0x\\1," APP_ICON_BYTES "${APP_ICON_HEX}")
configure_file("${CMAKE_CURRENT_LIST_DIR}/app/theme/app_icon_resource.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/generated/app_icon_resource.h" @ONLY)

function(target_link_system_wxwidgets TARGET_NAME)
    if(APPLE AND NOT wxWidgets_CONFIG_EXECUTABLE)
        find_program(wxWidgets_CONFIG_EXECUTABLE
            NAMES wx-config
            HINTS /opt/homebrew/bin /usr/local/bin
            DOC "Location of wxWidgets library configuration provider binary (wx-config)."
        )
    endif()

    find_package(wxWidgets 3 REQUIRED COMPONENTS core net base)
    if(wxWidgets_VERSION)
        set(WX_VERSION ${wxWidgets_VERSION})
    else()
        set(WX_VERSION ${wxWidgets_VERSION_STRING})
    endif()
    if(WX_VERSION AND NOT WX_VERSION MATCHES "^3\\.")
        message(FATAL_ERROR "Unsupported wxWidgets ${WX_VERSION}. Install a wxWidgets 3.x development package.")
    endif()
    target_link_libraries(${TARGET_NAME} PRIVATE wxWidgets::wxWidgets)

    if(LINUX)
        find_package(PkgConfig REQUIRED)
        pkg_check_modules(GTK3 QUIET IMPORTED_TARGET gtk+-3.0)
        if(NOT GTK3_FOUND)
            message(FATAL_ERROR "GTK 3 not found. Install the GTK 3 development package, e.g. libgtk-3-dev/libgtk3-dev.")
        endif()
        target_link_libraries(${TARGET_NAME} PRIVATE PkgConfig::GTK3 stdc++ m)
    endif()
endfunction()

function(target_link_windows_wxwidgets TARGET_NAME)
    set(WX_PREBUILT_ARCH "${PASSEPARTOUT_WINDOWS_ARCH}")
    set(WX_PREBUILT_URL "${PASSEPARTOUT_WX_PREBUILT_BASE_URL}/wxwidgets-windows-${WX_PREBUILT_ARCH}.zip")
    if(PASSEPARTOUT_WX_PREBUILT_DIR)
        set(WX_PREBUILT_DIR "${PASSEPARTOUT_WX_PREBUILT_DIR}")
    else()
        if(NOT PASSEPARTOUT_WX_PREBUILT_BASE_URL)
            message(FATAL_ERROR "PASSEPARTOUT_WX_PREBUILT_BASE_URL is required when no local prebuilt is supplied")
        endif()
        include(FetchContent)
        FetchContent_Declare(PassepartoutWxWidgets
            URL "${WX_PREBUILT_URL}"
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
            SOURCE_SUBDIR cmake-no-add-subdirectory
        )
        FetchContent_MakeAvailable(PassepartoutWxWidgets)
        set(WX_PREBUILT_DIR "${passepartoutwxwidgets_SOURCE_DIR}")
    endif()
    set(WX_LIB_DIR "${WX_PREBUILT_DIR}/lib/vc_${WX_PREBUILT_ARCH}_lib")

    if(EXISTS "${WX_PREBUILT_DIR}/include/wx/wx.h")
        set(WX_INCLUDE_DIR "${WX_PREBUILT_DIR}/include")
    elseif(EXISTS "${WX_PREBUILT_DIR}/include/wx-3.3/wx/wx.h")
        set(WX_INCLUDE_DIR "${WX_PREBUILT_DIR}/include/wx-3.3")
    else()
        message(FATAL_ERROR
            "wxWidgets Windows ${WX_PREBUILT_ARCH} headers not found under "
            "${WX_PREBUILT_DIR}/include. Check ${WX_PREBUILT_URL}, or set "
            "PASSEPARTOUT_WX_PREBUILT_DIR to an extracted prebuilt directory."
        )
    endif()

    set(WX_REQUIRED_FILES
        "${WX_LIB_DIR}/mswu/wx/setup.h"
        "${WX_LIB_DIR}/wxmsw33u_core.lib"
        "${WX_LIB_DIR}/wxbase33u_net.lib"
        "${WX_LIB_DIR}/wxbase33u.lib"
    )
    foreach(WX_REQUIRED_FILE IN LISTS WX_REQUIRED_FILES)
        if(NOT EXISTS "${WX_REQUIRED_FILE}")
            message(FATAL_ERROR
                "wxWidgets Windows ${WX_PREBUILT_ARCH} prebuilt file not found: "
                "${WX_REQUIRED_FILE}. "
                "Check ${WX_PREBUILT_URL}, or set PASSEPARTOUT_WX_PREBUILT_DIR "
                "to an extracted prebuilt directory."
            )
        endif()
    endforeach()

    message(STATUS "Using wxWidgets Windows ${WX_PREBUILT_ARCH} prebuilt: ${WX_PREBUILT_DIR}")
    # Opt into native per-monitor scaling instead of Windows bitmap scaling.
    target_sources(${TARGET_NAME} PRIVATE
        "${WX_INCLUDE_DIR}/wx/msw/wx_dpi_aware_pmv2.manifest"
    )
    target_include_directories(${TARGET_NAME} PRIVATE
        "${WX_LIB_DIR}/mswu"
        "${WX_INCLUDE_DIR}"
    )
    target_compile_definitions(${TARGET_NAME} PRIVATE
        __WXMSW__
        UNICODE
        _UNICODE
    )
    target_link_directories(${TARGET_NAME} PRIVATE "${WX_LIB_DIR}")
    target_link_libraries(${TARGET_NAME} PRIVATE
        wxmsw33u_core
        wxbase33u_net
        wxbase33u
        wxjpeg
        wxpng
        wxtiff
        wxzlib
        wxregexu
        kernel32
        user32
        gdi32
        gdiplus
        msimg32
        comdlg32
        winspool
        winmm
        shell32
        shlwapi
        comctl32
        ole32
        oleaut32
        uuid
        rpcrt4
        advapi32
        version
        ws2_32
        wininet
        oleacc
        uxtheme
        winhttp
    )
endfunction()

if(WIN32)
    target_link_windows_wxwidgets(passepartout)
else()
    target_link_system_wxwidgets(passepartout)
endif()
