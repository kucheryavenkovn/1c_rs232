# Cmake script for project AddInIESetup
# autor: 1C

CMAKE_MINIMUM_REQUIRED(VERSION 3.1 FATAL_ERROR)

if(NOT DEFINED AddInIEBuild)
    return()
endif()

PROJECT(${Addn_IESetup})
if (UNIX)
    MESSAGE(FATAL_ERROR "Must Windows only")
endif(UNIX)

find_program(MNSIS makensis)

if(MNSIS_NOTFOUND)
	MESSAGE(WARNING "NSIS not found.")
    return()
endif()

if (NOT TARGET_PLATFORM_32)
        SET(ADD_SUFFIX "x64")
    else()
        SET(ADD_SUFFIX "x86")
    endif()
    SET(ADD_BITS ${MySuffix2})
    
    set(ADAPTER ${Addn_IE}${MySuffix2}.dll)
    set(EXCOMP ${Addn_Native}${MySuffix1}${MySuffix2}_${Addn_VERSION}.dll)
    set(PRODUCT "AddInIE")
    set(OUTFILENAME ${PROJECT_NAME})
    configure_file(${CMAKE_SOURCE_DIR}/conf_data_in/AddInIESetup.nsh.in ${CMAKE_CURRENT_SOURCE_DIR}/AddInIESetup.nsh @ONLY)

if (SIGN_BAT)
    SET(SIGN_CMD1 ${SIGN_BAT} ${PROJECT_NAME}${MySuffix2}.exe)
    SET(SIGN_CMD2 )
elseif(SIGN_TOOL AND EXISTS ${SIGN_CERT})
    SET(SIGN_CMD1 ${SIGN_SHA1} ${PROJECT_NAME}${MySuffix2}.exe)
    SET(SIGN_CMD2 ${SIGN_SHA256} ${PROJECT_NAME}${MySuffix2}.exe)
else()
    SET(SIGN_CMD1)
    SET(SIGN_CMD2)
endif()

add_custom_target(${PROJECT_NAME} ALL
            COMMAND ${MNSIS}  AddInIESetup.nsi
            COMMAND ${SIGN_CMD1}
            COMMAND ${SIGN_CMD2}
            COMMAND ${CMAKE_COMMAND} -E rename ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}${MySuffix2}.exe ${PKG_OUTPUT_DIR}/${PROJECT_NAME}${MySuffix2}.exe
            DEPENDS AddInIESetup.nsh AddInIESetup.nsi 
            COMMENT "Build setup for IE..."
            SOURCES AddInIESetup.nsi AddInIESetup.nsh
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            )
ADD_DEPENDENCIES(${PROJECT_NAME} ${Addn_IE} ${Addn_Native})
