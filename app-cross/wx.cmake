target_link_directories(passepartout PRIVATE
    ${OUTPUT_DIR}/wx/lib
)
target_compile_options(passepartout PRIVATE
    -D_FILE_OFFSET_BITS=64
    -DwxDEBUG_LEVEL=0
)

# wx configuration is highly inconsistent across platforms
if(APPLE)
    target_include_directories(passepartout PRIVATE
        ${OUTPUT_DIR}/wx/include/wx-3.3
        ${OUTPUT_DIR}/wx/lib/wx/include/osx_cocoa-unicode-static-3.3
    )
    target_compile_options(passepartout PRIVATE
        -D__WXMAC__
        -D__WXOSX__
        -D__WXOSX_COCOA__
    )
    target_link_libraries(passepartout PRIVATE
        wx_osx_cocoau_core-3.3
        wx_baseu_net-3.3
        wx_baseu-3.3
        wxpng-3.3
    )
    target_link_libraries(passepartout PRIVATE
        "-framework Cocoa"
        "-framework Carbon"
        "-framework CoreFoundation"
        "-framework CoreGraphics"
        "-framework CoreServices"
        "-framework IOKit"
        iconv
        z
    )
elseif(LINUX)
    # Look up GTK+ 3.0 first
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GTK3 REQUIRED gtk+-3.0)
    include_directories(${GTK3_INCLUDE_DIRS})
    link_directories(${GTK3_LIBRARY_DIRS})
    add_definitions(${GTK3_CFLAGS_OTHER})

    target_include_directories(passepartout PRIVATE
        ${OUTPUT_DIR}/wx/include/wx-3.3
        ${OUTPUT_DIR}/wx/lib/wx/include/gtk3-unicode-static-3.3
    )
    target_compile_options(passepartout PRIVATE
        -D__WXGTK__
    )
    target_link_directories(passepartout PRIVATE
        ${OUTPUT_DIR}/wx/lib
    )
    # Link order is crucial here
    target_link_libraries(passepartout PRIVATE
        wx_gtk3u_core-3.3
        wx_baseu_net-3.3
        wx_baseu-3.3
        ${GTK3_LIBRARIES}
        png
        xkbcommon
        X11
    )
elseif(WIN32)
    target_include_directories(passepartout PRIVATE
        ${OUTPUT_DIR}/wx/include
        ${OUTPUT_DIR}/wx/include/msvc
    )
    target_compile_options(passepartout PRIVATE
        -D__WXMSW__
        -D_UNICODE
    )
    # MSVC complicates things as usual
    # - arm64 -> arm64
    # - amd64 -> x64
    string(TOLOWER ${CMAKE_SYSTEM_PROCESSOR} WX_VC_ARCH)
    if(WX_VC_ARCH STREQUAL "amd64")
        set(WX_VC_ARCH "x64")
    endif()
    target_link_directories(passepartout PRIVATE
        ${OUTPUT_DIR}/wx/lib/vc_${WX_VC_ARCH}_lib
    )
    # Append "d" suffix on Windows if Debug
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(WXD "d")
    endif()
    target_link_libraries(passepartout PRIVATE
        wxmsw33u${WXD}_core
        wxbase33u${WXD}_net
        wxbase33u${WXD}
    )
endif()
