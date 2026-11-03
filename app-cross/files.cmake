set(APP_SOURCES
    app/app.cc
    app/context/app_context.cc
    app/main.cc
    app/theme/theme.cc
)
if(WIN32)
    list(APPEND APP_SOURCES
        app/platform/windows_tunnel.cc
    )
endif()
