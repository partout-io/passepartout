set(PASSEPARTOUT_WX_PREBUILT_DIR "" CACHE PATH "Path to an extracted wxWidgets Windows prebuilt.")
set(PASSEPARTOUT_WX_PREBUILT_BASE_URL
    "https://github.com/partout-io/prebuilts/releases/latest/download"
    CACHE STRING
    "Base URL for wxWidgets Windows prebuilts."
)

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

function(get_windows_wxwidgets_arch OUT_VAR)
    if(CMAKE_GENERATOR_PLATFORM)
        set(WX_PLATFORM "${CMAKE_GENERATOR_PLATFORM}")
    elseif(CMAKE_VS_PLATFORM_NAME)
        set(WX_PLATFORM "${CMAKE_VS_PLATFORM_NAME}")
    elseif(CMAKE_CXX_COMPILER_ARCHITECTURE_ID)
        set(WX_PLATFORM "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}")
    elseif(CMAKE_C_COMPILER_ARCHITECTURE_ID)
        set(WX_PLATFORM "${CMAKE_C_COMPILER_ARCHITECTURE_ID}")
    elseif(CMAKE_CXX_COMPILER_TARGET)
        set(WX_PLATFORM "${CMAKE_CXX_COMPILER_TARGET}")
    elseif(CMAKE_C_COMPILER_TARGET)
        set(WX_PLATFORM "${CMAKE_C_COMPILER_TARGET}")
    elseif(DEFINED ENV{VSCMD_ARG_TGT_ARCH})
        set(WX_PLATFORM "$ENV{VSCMD_ARG_TGT_ARCH}")
    else()
        set(WX_PLATFORM "${CMAKE_SYSTEM_PROCESSOR}")
    endif()
    string(TOLOWER "${WX_PLATFORM}" WX_PLATFORM)

    if(WX_PLATFORM MATCHES "^(amd64|x86_64|x64)(-|$)")
        set(${OUT_VAR} "x64" PARENT_SCOPE)
    elseif(WX_PLATFORM MATCHES "^(arm64|aarch64)(-|$)")
        set(${OUT_VAR} "arm64" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Unsupported wxWidgets Windows prebuilt architecture: ${WX_PLATFORM}")
    endif()
endfunction()

function(target_link_windows_wxwidgets TARGET_NAME)
    get_windows_wxwidgets_arch(WX_PREBUILT_ARCH)
    set(WX_PREBUILT_URL "${PASSEPARTOUT_WX_PREBUILT_BASE_URL}/wxwidgets-windows-${WX_PREBUILT_ARCH}.zip")
    if(PASSEPARTOUT_WX_PREBUILT_DIR)
        set(WX_PREBUILT_DIR "${PASSEPARTOUT_WX_PREBUILT_DIR}")
    else()
        include(FetchContent)
        FetchContent_Declare(PassepartoutWxWidgets
            URL "${WX_PREBUILT_URL}"
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
            SOURCE_SUBDIR cmake-no-add-subdirectory
        )
        FetchContent_MakeAvailable(PassepartoutWxWidgets)
        FetchContent_GetProperties(PassepartoutWxWidgets)
        set(WX_PREBUILT_DIR "${passepartoutwxwidgets_SOURCE_DIR}")
    endif()
    set(WX_LIB_DIR "${WX_PREBUILT_DIR}/lib/vc_${WX_PREBUILT_ARCH}_lib")

    set(WX_REQUIRED_FILES
        "${WX_PREBUILT_DIR}/include/wx/wx.h"
        "${WX_LIB_DIR}/mswu/wx/setup.h"
        "${WX_LIB_DIR}/wxmsw33u_core.lib"
        "${WX_LIB_DIR}/wxbase33u_net.lib"
        "${WX_LIB_DIR}/wxbase33u.lib"
    )
    foreach(WX_REQUIRED_FILE IN LISTS WX_REQUIRED_FILES)
        if(NOT EXISTS "${WX_REQUIRED_FILE}")
            message(FATAL_ERROR
                "wxWidgets Windows ${WX_PREBUILT_ARCH} prebuilt not found. "
                "Check ${WX_PREBUILT_URL}, or set PASSEPARTOUT_WX_PREBUILT_DIR "
                "to an extracted prebuilt directory."
            )
        endif()
    endforeach()

    message(STATUS "Using wxWidgets Windows ${WX_PREBUILT_ARCH} prebuilt: ${WX_PREBUILT_DIR}")
    target_include_directories(${TARGET_NAME} PRIVATE
        "${WX_LIB_DIR}/mswu"
        "${WX_PREBUILT_DIR}/include"
    )
    target_compile_definitions(${TARGET_NAME} PRIVATE
        __WXMSW__
        UNICODE
        _UNICODE
        wxDEBUG_LEVEL=0
    )
    if(MSVC)
        set_target_properties(${TARGET_NAME} PROPERTIES
            MSVC_RUNTIME_LIBRARY "MultiThreadedDLL"
        )
        target_compile_definitions(${TARGET_NAME} PRIVATE
            _ITERATOR_DEBUG_LEVEL=0
        )
    endif()
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
