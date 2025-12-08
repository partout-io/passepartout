# Compile app files
file(GLOB_RECURSE PSP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc)
target_sources(passepartout PRIVATE ${PSP_SOURCES})

# Include app headers plus former ABI outputs
target_include_directories(passepartout PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${OUTPUT_DIR}
)

if(WIN32)
    # Build WinMain app on Windows
    set_target_properties(passepartout PROPERTIES WIN32_EXECUTABLE ON)
    # Specify absolute paths to work around lib prefix
    target_link_libraries(passepartout PRIVATE
        ${OUTPUT_DIR}/passepartout_shared.lib
        ${OUTPUT_DIR}/partout/libpartout.lib
        ${OUTPUT_DIR}/partout/libpartout_c.lib
        ${OUTPUT_DIR}/openssl/lib/libssl.lib
        ${OUTPUT_DIR}/openssl/lib/libcrypto.lib
        # wg-go has no export library
        #${OUTPUT_DIR}/wg-go/lib/libwg-go.lib
    )
else()
    target_link_directories(passepartout PRIVATE
        ${OUTPUT_DIR}
        ${OUTPUT_DIR}/partout
        ${OUTPUT_DIR}/openssl/lib
        ${OUTPUT_DIR}/wg-go/lib
    )
    target_link_libraries(passepartout PRIVATE
        passepartout_shared
        partout
        partout_c
        ssl
        crypto
        wg-go
    )
endif()

# libwg-go is omitted because loaded dynamically

# Configure Linux RPATH stuff
if(LINUX)
     set_target_properties(passepartout PROPERTIES
        BUILD_RPATH "\$ORIGIN"
        INSTALL_RPATH "\$ORIGIN"
        SKIP_BUILD_RPATH OFF
    )
endif()
