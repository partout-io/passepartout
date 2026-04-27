# Configure wxWidgets external project
if(WIN32)
    set(WX_GENERATOR "Visual Studio 17 2022")
else()
    set(WX_GENERATOR ${CMAKE_GENERATOR})
endif()
set(WX_ARGS
    -DCMAKE_INSTALL_PREFIX=${OUTPUT_DIR}/wx
    -DwxBUILD_SHARED=OFF
    -DwxBUILD_TESTS=OFF
    -DwxBUILD_SAMPLES=OFF
    -DwxBUILD_DEMOS=OFF
    -DwxBUILD_PRECOMP=OFF
    -DwxUSE_LIBWEBP=OFF
    -DwxUSE_WEBVIEW=OFF
)
ExternalProject_Add(wxWidgets
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/wx
    CMAKE_GENERATOR ${WX_GENERATOR}
    CMAKE_ARGS ${WX_ARGS}
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
)

# Require wxWidgets to build app executable
add_dependencies(passepartout wxWidgets)
target_compile_options(passepartout PRIVATE
    -D_FILE_OFFSET_BITS=64
    -DwxDEBUG_LEVEL=0
)
target_link_directories(passepartout PRIVATE
    ${OUTPUT_DIR}/wx/lib
)
# Linux seems to complain about this
if(LINUX)
    target_link_libraries(passepartout PRIVATE stdc++ m)
endif()

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
        "-framework QuartzCore"
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
