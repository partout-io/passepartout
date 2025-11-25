set(OUTPUT_DIR ${CMAKE_ARGV3})
set(APP_DIR ${CMAKE_ARGV4})

if(WIN32)
    set(OPENSSL_FOLDER bin)
else()
    set(OPENSSL_FOLDER lib)
endif()

# Bundle compiled binaries
file(GLOB LIBPARTOUT "${OUTPUT_DIR}/partout/libpartout*")
file(GLOB LIBSSL "${OUTPUT_DIR}/openssl/${OPENSSL_FOLDER}/libssl*")
file(GLOB LIBCRYPTO "${OUTPUT_DIR}/openssl/${OPENSSL_FOLDER}/libcrypto*")
file(GLOB LIBWGGO "${OUTPUT_DIR}/wg-go/lib/*wg-go*")
file(COPY ${LIBPARTOUT} DESTINATION ${APP_DIR})
file(COPY ${LIBSSL} DESTINATION ${APP_DIR})
file(COPY ${LIBCRYPTO} DESTINATION ${APP_DIR})
file(COPY ${LIBWGGO} DESTINATION ${APP_DIR})

# Clean up static libs and metadata
file(GLOB CLEANUP
    ${APP_DIR}/*.a
    ${APP_DIR}/*.lib
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
        Foundation.dll
        FoundationEssentials.dll
        FoundationInternationalization.dll
        _FoundationICU.dll
    )
elseif(LINUX)
    list(APPEND SWIFT_LIBS
        libBlocksRuntime.so
        libdispatch.so
        libswiftCore.so
        libswiftDispatch.so
        libswiftGlibc.so
        libswiftSwiftOnoneSupport.so
        libswiftSynchronization.so
        libswift_Concurrency.so
        libswift_RegexParser.so
        libswift_StringProcessing.so
        libFoundation.so
        libFoundationEssentials.so
        libFoundationInternationalization.so
        lib_FoundationICU.so
    )
endif()

foreach(lib ${PREBUILT_LIBS})
    file(COPY ${lib} DESTINATION ${APP_DIR})
endforeach()
foreach(lib ${SWIFT_LIBS})
    file(COPY "$ENV{SWIFT_RUNTIME}/${lib}" DESTINATION ${APP_DIR})
endforeach()
