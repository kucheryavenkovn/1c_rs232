# Cmake script for project AddInIE
# autor: 1C

CMAKE_MINIMUM_REQUIRED(VERSION 3.6 FATAL_ERROR)

PROJECT(${Addn_IE})

if (NOT UNIX)
    SET(CMAKE_BUILD_TYPE Release)
    IF (NOT "${CMAKE_GENERATOR_TOOLSET}" STREQUAL "${VS_TOOLSET_FOR_BROWSERS_REQUIRED}")
        MESSAGE(WARNING "Building ${PROJECT_NAME} disabled! Supported Visual Studio: 12 (v120_xp), 14 (v120_xp), 15 (v120_xp) or above with v120_xp toolset")
        RETURN()
    ENDIF()
ELSE()
    MESSAGE(WARNING "Must Windows only")
    RETURN()
endif(NOT UNIX)

SET(AddInIEBuild TRUE PARENT_SCOPE)
CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/conf_data_in/AddInIE.rc.in ${CMAKE_CURRENT_SOURCE_DIR}/AddInIE.rc)
CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/conf_data_in/AddInIE.def.in ${CMAKE_CURRENT_SOURCE_DIR}/AddInIE.def)
#----------------------------------------------------------------------------------------------------------------#
#--source files-------------------
SET(AddInIE_SRC 
    Resource.h
    config.cpp
    config.h
    stdafx.cpp
    stdafx.h
    targetver.h

    AddInIE.rc
    AddInSite.rgs
    AddInWeb.rgs
    )
SET(AddInIEDef_SRC AddInIE.def)
set_source_files_properties(AddInWeb.rgs AddInSite.rgs PROPERTIES HEADER_FILE_ONLY TRUE)
#--source files end---------------
#----------------------------------------------------------------------------------------------------------------#
ADD_DEFINITIONS(-DWIN32 -DUNICODE -D_USRDLL -D_MERGE_PROXYSTUB)

IF(NOT TARGET_PLATFORM_32)
    SET(AMD_64 "/amd64")
ENDIF()

set(MIDL_OUTPUT
    ${CMAKE_CURRENT_SOURCE_DIR}/AddInIE_i.h
    ${CMAKE_CURRENT_SOURCE_DIR}/AddInIE_i.c
    ${CMAKE_CURRENT_SOURCE_DIR}/AddInIE.tlb
    )
set(MIDL_FILE
    ${CMAKE_CURRENT_LIST_DIR}/AddInIE.idl
    )
add_custom_command(
    OUTPUT ${MIDL_OUTPUT}
    COMMAND midl /h ${CMAKE_CURRENT_SOURCE_DIR}/AddInIE_i.h 
        /iid ${CMAKE_CURRENT_SOURCE_DIR}/AddInIE_i.c
        /proxy ${CMAKE_CURRENT_SOURCE_DIR}/AddInIE_p.c 
        /dlldata ${CMAKE_CURRENT_SOURCE_DIR}/dlldata.c 
        /tlb ${CMAKE_CURRENT_SOURCE_DIR}/AddInIE.tlb
        ${AMD_64} ${MIDL_FILE}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    MAIN_DEPENDENCY ${MIDL_FILE}
    BYPRODUCTS ${MIDL_OUTPUT}
    VERBATIM
    )

SET(ADDITIONAL_CLEAN_FILES ${MIDL_OUTPUT})
SET(CMAKE_LIBRARY_PATH ${CMAKE_SOURCE_DIR}/../lib)
LINK_DIRECTORIES(${CMAKE_SOURCE_DIR}/../lib)
INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR}/../include)

add_library(${PROJECT_NAME} SHARED ${AddInIE_SRC} ${MIDL_OUTPUT} ${AddInIEDef_SRC})

set_target_properties(${PROJECT_NAME} PROPERTIES LINK_SEARCH_START_STATIC 1)
FIND_LIBRARY(1CEADNWEBIE "1CEAdnWebIE${MySuffix2}")
TARGET_LINK_LIBRARIES(${PROJECT_NAME} ${1CEADNWEBIE})
set_target_properties(${PROJECT_NAME} PROPERTIES LINK_SEARCH_END_STATIC 1)

TARGET_LINK_LIBRARIES(${PROJECT_NAME}  RpcRT4.lib oleaut32.lib)

SET_TARGET_PROPERTIES( ${PROJECT_NAME} PROPERTIES
   OUTPUT_NAME ${PROJECT_NAME}${MySuffix2} 
   )
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
