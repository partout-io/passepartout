if(ANDROID)
    # Link Swift runtime statically into .so
    set(SWIFT_STATIC_DIR
        $ENV{SWIFT_ANDROID_RESOURCE_DIR}/android
    )
    set(SWIFT_LIBS
        swift_Concurrency
        swift_StringProcessing
        swift_RegexParser
        swiftAndroid
        swiftCore
        swiftDispatch
        dispatch
        BlocksRuntime
    )
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        list(APPEND ${SWIFT_LIBS} swiftSwiftOnoneSupport)
    endif()
    foreach(lib ${SWIFT_LIBS})
        target_link_libraries(passepartout_shared PRIVATE
            ${SWIFT_STATIC_DIR}/lib${lib}.a
        )
    endforeach()
endif()
