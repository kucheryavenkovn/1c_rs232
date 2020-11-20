# Cmake script for project AddInChr
# autor: 1C

CMAKE_MINIMUM_REQUIRED(VERSION 3.6 FATAL_ERROR)

PROJECT(${Addn_Chrome})

if (NOT UNIX)
    IF (NOT "${CMAKE_GENERATOR_TOOLSET}" STREQUAL "${VS_TOOLSET_FOR_BROWSERS_REQUIRED}")
        MESSAGE(WARNING "Building ${PROJECT_NAME} disabled! Supported Visual Studio: 12 (v120_xp), 14 (v120_xp), 15 (v120_xp) or above with v120_xp toolset")
        RETURN()
    ENDIF()
endif(NOT UNIX)

SET(AddInChrBuild TRUE PARENT_SCOPE)
IF(WIN32)
    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/conf_data_in/AddInChrome.rc.in ${CMAKE_CURRENT_SOURCE_DIR}/AddInChrome.rc)
ENDIF()
#----------------------------------------------------------------------------------------------------------------#
#--source files-------------------
SET(AddInChr_SRC 
    config.cpp
    config.h
    AddInChrome.rc
    )
#--source files end---------------
#----------------------------------------------------------------------------------------------------------------#

IF (UNIX)
    if (NOT APPLE)
        set_source_files_properties(${AddInChr_SRC}
              PROPERTIES COMPILE_FLAGS
              "-fshort-wchar")
    else()
        set_source_files_properties(${AddInChr_SRC}
              PROPERTIES COMPILE_FLAGS
              "-fshort-wchar -stdlib=libc++")
        ADD_DEFINITIONS(-D__APPLE__ )
    endif()
ELSE()
    ADD_DEFINITIONS(-DWIN32 )
ENDIF()

IF (APPLE)
    SET(MAC_LIBRARIES
            "-framework Carbon"
            "-framework Cocoa"
            "-framework CoreFoundation"
            #"-framework AudioToolbox"
            "-framework IOKit"
            "-framework OpenGL"
            "-framework System"
            "-framework WebKit"
            "-lobjc")
ENDIF()

SET(CMAKE_LIBRARY_PATH ${CMAKE_SOURCE_DIR}/../lib)
LINK_DIRECTORIES(${CMAKE_SOURCE_DIR}/../lib)
INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR}/../include)

ADD_EXECUTABLE(${PROJECT_NAME} ${AddInChr_SRC})
set_target_properties(${PROJECT_NAME} PROPERTIES 
        CXX_STANDARD 11
        CXX_STANDARD_REQUIRED ON
        POSITION_INDEPENDENT_CODE ON
        )

set_target_properties(${PROJECT_NAME} PROPERTIES LINK_SEARCH_START_STATIC 1)
IF (UNIX)
    SET(1CEADNWEBChr "1CEAddInWebChr${MySuffix1}${MySuffix2}")
ELSE()
    SET(1CEADNWEBChr "1CEAdnWebChr${MySuffix1}${MySuffix2}")
ENDIF()
TARGET_LINK_LIBRARIES(${PROJECT_NAME} ${1CEADNWEBChr})
set_target_properties(${PROJECT_NAME} PROPERTIES LINK_SEARCH_END_STATIC 1)

ADD_DEPENDENCIES(${PROJECT_NAME} ${Addn_Native})

IF (UNIX)
    IF (APPLE)
        set_target_properties( ${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/ext/Application\ Support/${MYCOMPANY}/${ADN_NAME})
        TARGET_LINK_LIBRARIES(${PROJECT_NAME} dl Threads::Threads ${MAC_LIBRARIES} panel c++ )
    ELSE()
        TARGET_LINK_LIBRARIES(${PROJECT_NAME} dl Threads::Threads gtk-x11-2.0 gobject-2.0)
        set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-Wl,--no-undefined")
    ENDIF()
ELSE()
    TARGET_LINK_LIBRARIES(${PROJECT_NAME} RpcRT4.lib)
ENDIF()

SET_TARGET_PROPERTIES( ${PROJECT_NAME} PROPERTIES
    OUTPUT_NAME ${PROJECT_NAME}${MySuffix1}${MySuffix2}
   )

if(UNIX AND NOT APPLE)
    SET(STRIP_CMD)
    if (STRIP)
        SET(STRIP_CMD ${STRIP} $<TARGET_FILE:${PROJECT_NAME}> -f ${PDB_DIR}/$<TARGET_FILE_NAME:${PROJECT_NAME}>.debug)
    endif()
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD 
            COMMAND ${STRIP_CMD}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${TMP_DIR}
            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${PROJECT_NAME}> ${TMP_DIR}/
            COMMENT "Copy ${PROJECT_NAME}"
            MAIN_DEPENDENCY ${PROJECT_NAME}
            )
elseif(WIN32)
    if (SIGN_BAT)
        SET(SIGN_CMD1 ${SIGN_BAT} $<TARGET_FILE:${PROJECT_NAME}>)
        SET(SIGN_CMD2 )
    elseif(SIGN_TOOL AND EXISTS ${SIGN_CERT})
        SET(SIGN_CMD1 ${SIGN_SHA1} $<TARGET_FILE:${PROJECT_NAME}>)
        SET(SIGN_CMD2 ${SIGN_SHA256} $<TARGET_FILE:${PROJECT_NAME}>)
    else()
        SET(SIGN_CMD1)
        SET(SIGN_CMD2)
    endif()
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD 
            COMMAND ${SIGN_CMD1}
            COMMAND ${SIGN_CMD2}
            COMMAND ${CMAKE_COMMAND} -E rename $<TARGET_FILE:${PROJECT_NAME}> ${LIB_DIR}/$<TARGET_FILE_NAME:${PROJECT_NAME}>
            COMMENT "Copy ${PROJECT_NAME}"
            MAIN_DEPENDENCY ${PROJECT_NAME}
            )
endif()

get_target_property(APPNAME ${PROJECT_NAME} OUTPUT_NAME)

IF (APPLE)
    SET(PKG_NAME "AddInChrOSX")
    set(JSON_FF "${Addn_Mainfest}.ff.json")
    set(JSON_CHR "${Addn_Mainfest}.json")
    set(ADAPTER "/Library/Application Support/${MYCOMPANY}/${ADN_NAME}/${APPNAME}")
    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/conf_data_in/manifest.json.in 
        ${CMAKE_CURRENT_BINARY_DIR}/chr/Google/Chrome/NativeMessagingHosts/${JSON_CHR} @ONLY)

    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/conf_data_in/manifest.ff.json.in 
        ${CMAKE_CURRENT_BINARY_DIR}/ff/Application\ Support/Mozilla/NativeMessagingHosts/${JSON_CHR} @ONLY)

    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/conf_data_in/distribution.plist.in ${CMAKE_CURRENT_BINARY_DIR}/distribution.plist @ONLY)

    #copy library
    get_target_property(NATIVE_LIB ${Addn_Native} OUTPUT_NAME)
    SET(NATIVE ${CMAKE_SHARED_LIBRARY_PREFIX}${NATIVE_LIB}${CMAKE_SHARED_LIBRARY_SUFFIX})
    
    add_custom_target(copy-lib ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/ext/Application\ Support/${MYCOMPANY}/${ADN_NAME}/${NATIVE})
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/ext/Application\ Support/${MYCOMPANY}/${ADN_NAME}/${NATIVE}
                   COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${Addn_Native}>
                        ${CMAKE_CURRENT_BINARY_DIR}/ext/Application\ Support/${MYCOMPANY}/${ADN_NAME}/${NATIVE}
                   DEPENDS ${Addn_Native}
                   COMMENT "Copy target $<TARGET_FILE:${Addn_Native}>"
                )

    SET(CUR_VER "8.3.0.${Addn_VERSION}")
    add_custom_target( pkgbuild DEPENDS ${PROJECT_NAME} copy-lib
        COMMAND pkgbuild --install-location /Library --version ${CUR_VER} --identifier "$<LOWER_CASE:${Addn_Mainfest}>.ff" --sign "Developer ID Installer: ${SIGNCERT}" --root ${CMAKE_CURRENT_BINARY_DIR}/ff ${CMAKE_CURRENT_BINARY_DIR}/ff.pkg

        COMMAND pkgbuild --install-location /Library --version ${CUR_VER} --identifier "$<LOWER_CASE:${Addn_Mainfest}>.chr" --sign "Developer ID Installer: ${SIGNCERT}" --root ${CMAKE_CURRENT_BINARY_DIR}/chr ${CMAKE_CURRENT_BINARY_DIR}/chrome.pkg
        
        COMMAND pkgbuild --install-location /Library --version ${CUR_VER} --identifier "$<LOWER_CASE:${Addn_Mainfest}>.ext" --sign "Developer ID Installer: ${SIGNCERT}" --root ${CMAKE_CURRENT_BINARY_DIR}/ext ${CMAKE_CURRENT_BINARY_DIR}/${ADN_NAME}.pkg
    )
    add_custom_target( productbuild DEPENDS pkgbuild
        COMMAND productbuild --distribution ${CMAKE_CURRENT_BINARY_DIR}/distribution.plist --package-path ${CMAKE_CURRENT_BINARY_DIR}/ff.pkg --package-path ${CMAKE_CURRENT_BINARY_DIR}/chrome.pkg --package-path ${CMAKE_CURRENT_BINARY_DIR}/${ADN_NAME}.pkg ${CMAKE_CURRENT_BINARY_DIR}/${PKG_NAME}.pkg
    )
    add_custom_target( productsign ALL DEPENDS productbuild
        COMMAND productsign --sign "Developer ID Installer: ${SIGNCERT}"  ${CMAKE_CURRENT_BINARY_DIR}/${PKG_NAME}.pkg ${PKG_OUTPUT_DIR}/${PKG_NAME}.pkg
    )
    add_custom_target( zipdebug DEPENDS ${PROGNAME}
        COMMAND dsymutil -o ${PROJECT_NAME}.dSYM $<TARGET_FILE:${PROJECT_NAME}>
        COMMAND zip -r ${PDB_DIR}/${PROJECT_NAME}_${Addn_VERSION}.zip ${PROJECT_NAME}.dSYM
    )
ENDIF()
