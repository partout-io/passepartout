if(WIN32)
    set(OPENSSL_FOLDER bin)
    file(GLOB LIBPASSEPARTOUT
        "${OUTPUT_DIR}/passepartout.dll"
        "${OUTPUT_DIR}/passepartout.lib"
        "${OUTPUT_DIR}/passepartout.pdb"
    )
else()
    set(OPENSSL_FOLDER lib)
    file(GLOB LIBPASSEPARTOUT "${OUTPUT_DIR}/libpassepartout*")
endif()

# Bundle compiled binaries
file(GLOB LIBSSL "${OUTPUT_DIR}/openssl/${OPENSSL_FOLDER}/libssl*")
file(GLOB LIBCRYPTO "${OUTPUT_DIR}/openssl/${OPENSSL_FOLDER}/libcrypto*")
file(GLOB LIBWGGO "${OUTPUT_DIR}/wg-go/lib/*wg-go*")
file(MAKE_DIRECTORY "${DIST_DIR}")
foreach(lib IN LISTS LIBPASSEPARTOUT LIBSSL LIBCRYPTO LIBWGGO)
    file(COPY "${lib}" DESTINATION "${DIST_DIR}")
endforeach()

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
    file(COPY "${lib}" DESTINATION "${DIST_DIR}")
endforeach()
foreach(lib ${SWIFT_LIBS})
    file(COPY "$ENV{SWIFT_RUNTIME}/${lib}" DESTINATION "${DIST_DIR}")
endforeach()

set(LIBPASSEPARTOUT_BINARY "${DIST_DIR}/libpassepartout.${LIBEXT}")
if(STRIP AND NOT WIN32 AND EXISTS "${LIBPASSEPARTOUT_BINARY}")
    execute_process(COMMAND "${STRIP}" "${LIBPASSEPARTOUT_BINARY}")
endif()
