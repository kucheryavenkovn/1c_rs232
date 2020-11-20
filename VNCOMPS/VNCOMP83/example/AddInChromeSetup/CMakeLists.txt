# Cmake script for project AddInIESetup
# autor: 1C

CMAKE_MINIMUM_REQUIRED(VERSION 3.6 FATAL_ERROR)

if(NOT DEFINED AddInChrBuild)
    return()
endif()

PROJECT(${Addn_ChromeSetup})

if (WIN32)
    find_program(NSIS makensis)

    if(NSIS_NOTFOUND)
        MESSAGE(WARNING "NSIS not found.")
        return()
    endif()

    if (NOT TARGET_PLATFORM_32)
        SET(ADD_SUFFIX "x64")
    else()
        SET(ADD_SUFFIX "x86")
    endif()
    SET(ADD_BITS ${MySuffix2})
    
    set(JSON_FF "${Addn_Mainfest}.ff.json")
    set(JSON_CHR "${Addn_Mainfest}.json")
    set(ADAPTER ${Addn_Chrome}${MySuffix1}${MySuffix2}.exe)
    set(EXCOMP ${Addn_Native}${MySuffix1}${MySuffix2}_${Addn_VERSION}.dll)
    set(PRODUCT "AddInChrome")
    set(OUTFILENAME ${PROJECT_NAME})

    configure_file(${CMAKE_SOURCE_DIR}/conf_data_in/manifest.ff.json.in ${CMAKE_CURRENT_SOURCE_DIR}/${JSON_FF} @ONLY)
    configure_file(${CMAKE_SOURCE_DIR}/conf_data_in/manifest.json.in ${CMAKE_CURRENT_SOURCE_DIR}/${JSON_CHR} @ONLY)
    configure_file(${CMAKE_SOURCE_DIR}/conf_data_in/AddInChromeSetup.nsh.in ${CMAKE_CURRENT_SOURCE_DIR}/AddInChromeSetup.nsh @ONLY)

    if (SIGN_BAT)
        SET(SIGN_CMD1 ${SIGN_BAT} ${PROJECT_NAME}${MySuffix2}.exe)
        SET(SIGN_CMD2 )
    elseif(SIGN_TOOL AND EXISTS ${SIGN_CERT})
        SET(SIGN_CMD1 ${SIGN_TOOL} ${SIGN_SHA1} ${PROJECT_NAME}${MySuffix2}.exe)
        SET(SIGN_CMD2 ${SIGN_TOOL} ${SIGN_SHA256} ${PROJECT_NAME}${MySuffix2}.exe)
    else()
        SET(SIGN_CMD1)
        SET(SIGN_CMD2)
    endif()
    
    add_custom_target(${PROJECT_NAME} ALL
                COMMAND ${NSIS} AddInChromeSetup.nsi 
                COMMAND ${SIGN_CMD1}
                COMMAND ${SIGN_CMD2}
                COMMAND ${CMAKE_COMMAND} -E rename ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}${MySuffix2}.exe ${PKG_OUTPUT_DIR}/${PROJECT_NAME}${MySuffix2}.exe
                DEPENDS ${JSON_FF} ${JSON_CHR}
                COMMENT "Build setup for Google Chrome and Mozilla Firefox..."
                SOURCES AddInChromeSetup.nsi AddInChromeSetup.nsh
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                )
    ADD_DEPENDENCIES(${PROJECT_NAME} ${Addn_Chrome} ${Addn_Native})
elseif(UNIX AND NOT APPLE)
    #create makeself 
    FIND_PROGRAM(MKSLF makeself.sh HINTS ENV PATH ${CMAKE_CURRENT_SOURCE_DIR})
    IF(NOT MKSLF)
        FIND_PROGRAM(MKSLF makeself)
    ENDIF()

    IF(NOT MKSLF)
        message(WARNING "makeself.sh not found!")
        return()
    ENDIF()
    
    SET(ADAPTER "HOST_PATH")
    set(JSON_FF "${Addn_Mainfest}.ff.json")
    set(JSON_CHR "${Addn_Mainfest}.json")

    configure_file(${CMAKE_SOURCE_DIR}/conf_data_in/install_host.sh.in ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.sh @ONLY)
    configure_file(${CMAKE_SOURCE_DIR}/conf_data_in/manifest.ff.json.in ${CMAKE_CURRENT_BINARY_DIR}/${JSON_FF} @ONLY)
    configure_file(${CMAKE_SOURCE_DIR}/conf_data_in/manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/${JSON_CHR} @ONLY)
    
    add_custom_target( copy_json DEPENDS ${Addn_Chrome} ${Addn_Native}
            COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/${JSON_FF} ${TMP_DIR}/${JSON_FF}
            COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/${JSON_CHR} ${TMP_DIR}/${JSON_CHR}
            COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.sh ${TMP_DIR}/${PROJECT_NAME}.sh
            COMMENT "Copy json files"
        )

    add_custom_target(${PROJECT_NAME} ALL COMMAND ${MKSLF} --nox11 
                ${TMP_DIR}/ #archive dir
                ${PKG_OUTPUT_DIR}/${PROJECT_NAME}${MySuffix1}${MySuffix2}.sh #file name
                "${PROJECT_NAME}" #label
                ./${PROJECT_NAME}.sh #startup script
                DEPENDS copy_json
                WORKING_DIRECTORY ${TMP_DIR}
                )
    ADD_DEPENDENCIES(${PROJECT_NAME} ${Addn_Chrome} ${Addn_Native})
endif()
