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
file(COPY ${LIBPASSEPARTOUT} DESTINATION ${DIST_DIR})
file(COPY ${LIBSSL} DESTINATION ${DIST_DIR})
file(COPY ${LIBCRYPTO} DESTINATION ${DIST_DIR})
file(COPY ${LIBWGGO} DESTINATION ${DIST_DIR})

# Clean up static libs and metadata
file(GLOB CLEANUP
    ${DIST_DIR}/*.a
    ${DIST_DIR}/*.d
    ${DIST_DIR}/*.lib
    # Keep for debugging
    ${DIST_DIR}/*.exp
    ${DIST_DIR}/*.pdb
    ${DIST_DIR}/*.ilk
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
        FoundationEssentials.dll
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
    file(COPY ${lib} DESTINATION ${DIST_DIR})
endforeach()
foreach(lib ${SWIFT_LIBS})
    file(COPY "$ENV{SWIFT_RUNTIME}/${lib}" DESTINATION ${DIST_DIR})
endforeach()

if(STRIP AND NOT WIN32)
    execute_process(COMMAND ${STRIP} ${DIST_DIR}/libpassepartout.${LIBEXT})
endif()
