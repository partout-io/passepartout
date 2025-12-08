if(WIN32)
    target_link_directories(passepartout PRIVATE
        $ENV{SWIFT_SDK}
    )
    target_link_libraries(passepartout PRIVATE
        swiftCore
    )
elseif(LINUX)
    set(SWIFT_STATIC_DIR
        $ENV{SWIFT_SDK}/../../swift_static/linux
    )
    set(SWIFT_LIBS
        swift_Concurrency
        swift_StringProcessing
        swift_RegexParser
        swiftCore
        swiftRuntime
        swiftDispatch
        swiftGlibc
        dispatch
        BlocksRuntime
    )
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        list(APPEND ${SWIFT_LIBS} swiftSwiftOnoneSupport)
    endif()
    foreach(lib ${SWIFT_LIBS})
        target_link_libraries(passepartout PRIVATE
            ${SWIFT_STATIC_DIR}/lib${lib}.a
        )
    endforeach()
endif()
