set(APP_DIR ${OUTPUT_DIR}/${DIST_DIR})

if(WIN32)
    set(OPENSSL_FOLDER bin)
else()
    set(OPENSSL_FOLDER lib)
endif()

# Bundle compiled binaries
file(GLOB LIBPASSEPARTOUT "${OUTPUT_DIR}/*passepartout*")
file(GLOB LIBSSL "${OUTPUT_DIR}/openssl/${OPENSSL_FOLDER}/libssl*")
file(GLOB LIBCRYPTO "${OUTPUT_DIR}/openssl/${OPENSSL_FOLDER}/libcrypto*")
file(GLOB LIBWGGO "${OUTPUT_DIR}/wg-go/lib/*wg-go*")
file(COPY ${LIBPASSEPARTOUT} DESTINATION ${APP_DIR})
file(COPY ${LIBSSL} DESTINATION ${APP_DIR})
file(COPY ${LIBCRYPTO} DESTINATION ${APP_DIR})
file(COPY ${LIBWGGO} DESTINATION ${APP_DIR})

# Clean up static libs and metadata
file(GLOB CLEANUP
    ${APP_DIR}/*.a
    ${APP_DIR}/*.d
    ${APP_DIR}/*.lib
    # Keep for debugging
    ${APP_DIR}/*.exp
    ${APP_DIR}/*.pdb
    ${APP_DIR}/*.ilk
)
foreach(file in ${CLEANUP})
    file(REMOVE ${file})
endforeach()

# Bundle prebuilt binaries and Swift runtime
set(PREBUILT_LIBS "")
set(SWIFT_LIBS "")
if(WIN32)
    list(APPEND PREBUILT_LIBS
        ${OUTPUT_DIR}/wintun/wintun.dll
    )
    list(APPEND SWIFT_LIBS
        BlocksRuntime.dll
        dispatch.dll
        swiftCore.dll
        swiftCRT.dll
        swiftDispatch.dll
        swiftWinSDK.dll
        swift_Concurrency.dll
        swift_RegexParser.dll
        swift_StringProcessing.dll
    )
endif()

foreach(lib ${PREBUILT_LIBS})
    file(COPY ${lib} DESTINATION ${APP_DIR})
endforeach()
foreach(lib ${SWIFT_LIBS})
    file(COPY "$ENV{SWIFT_RUNTIME}/${lib}" DESTINATION ${APP_DIR})
endforeach()

if(STRIP AND NOT WIN32)
    execute_process(COMMAND ${STRIP} ${APP_DIR}/libpassepartout.${LIBEXT})
endif()
