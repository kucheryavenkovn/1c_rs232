# Cmake script for project AddIn
# autor: 1C
cmake_minimum_required (VERSION 3.6)

if (WIN32)
    if ("${CMAKE_GENERATOR}" MATCHES "Visual Studio ([0-9]+)")
        if (NOT ${CMAKE_MATCH_1} GREATER_EQUAL 15)
            message(FATAL_ERROR "Supported Visual Studio: 2017 or above with v141_xp toolset")
        endif()
    endif()
    IF(${CMAKE_VERSION} VERSION_GREATER_EQUAL 3.15.0)
        cmake_policy(SET CMP0091 NEW)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"  CACHE STRING "Runtime lib" FORCE)
    endif()
endif(WIN32)
SET(CMAKE_CONFIGURATION_TYPES "Release;Debug" CACHE STRING "Build configurations" FORCE)
if (NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE Release CACHE STRING "Build configurations" FORCE)
endif()

project (AddIn)
include(${CMAKE_SOURCE_DIR}/settings.cmake)
set(VS_TOOLSET_FOR_BROWSERS_REQUIRED "v141_xp")
#-----------------------------------------------------------------------------
# Minimum compiler version check: Microsoft C/C++ >= 18.0 (aka VS 2013 aka VS 12.0)
if (MSVC AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 19.0)
  message(FATAL_ERROR "Only Microsoft Visual Studio 2017 or later is currently supported.")
endif ()

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    IF(${CMAKE_VERSION} VERSION_LESS 3.15.0)
        foreach(flag
           CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
           CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
            CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
            if(${flag} MATCHES "/MD")
                string(REGEX REPLACE "/MD" "/MT" ${flag} "${${flag}}")
                set(${flag} ${${flag}} CACHE "STRING" "Compilation flags" FORCE)
            endif()
        endforeach()
    endif()
endif()
if (WIN32)
    if (${CMAKE_SIZEOF_VOID_P} EQUAL 8 OR "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}" STREQUAL "x64")
        OPTION(TARGET_PLATFORM_32 "Build target for i386" OFF)
    else()
        OPTION(TARGET_PLATFORM_32 "Build target for i386" ON)
    endif()
else()
    OPTION(TARGET_PLATFORM_32 "Build target for i386" ON)
endif()

MARK_AS_ADVANCED(TARGET_PLATFORM_32)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
#-----------------------------------------------------------------------------
# Minimum compiler version check: GCC >= 4.8
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND
    CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.8)
  message(FATAL_ERROR "GCC 4.8 or later is required.")
endif ()

if (NOT UNIX)
    IF(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
       SET(CMAKE_BUILD_TYPE "Release" CACHE STRING "Compilator type" FORCE)
    ENDIF(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
endif(NOT UNIX)

if (UNIX)
    set(MySuffix1 "Lin")
    if (APPLE)
        set(MySuffix1 "Mac")
    endif(APPLE)
else(UNIX)
    set(MySuffix1 "Win")
endif(UNIX)

set(CMAKE_SKIP_RPATH ON CACHE BOOL "")

if(UNIX AND NOT APPLE)
    set(CMAKE_LINK_WHAT_YOU_USE ON)
endif()

if (TARGET_PLATFORM_32)
    set(MySuffix2 "32")
    if (UNIX)
        SET(ARCH_FLAG "-m32")
    endif()
else()
    set(MySuffix2 "64")
    if (UNIX)
        SET(ARCH_FLAG "-m64")
    endif()
endif()

if (UNIX)
    foreach(flag
        CMAKE_EXE_LINKER_FLAGS CMAKE_MODULE_LINKER_FLAGS CMAKE_SHARED_LINKER_FLAGS CMAKE_C_FLAGS CMAKE_CXX_FLAGS )
        if(NOT ${flag} MATCHES ${ARCH_FLAG})
            set(${flag} ${${flag}} ${ARCH_FLAG} CACHE "STRING" "Linker flags" FORCE)
        endif()
    endforeach()
endif()

set(LIB_DIR ${CMAKE_SOURCE_DIR}/bin)
set(EXE_DIR ${CMAKE_SOURCE_DIR}/bin)
set(ARCH_DIR ${CMAKE_SOURCE_DIR}/bin)
set(PDB_DIR ${CMAKE_SOURCE_DIR}/debug_info)
SET (PKG_OUTPUT_DIR ${CMAKE_SOURCE_DIR}/pkg)

file(MAKE_DIRECTORY ${LIB_DIR})
file(MAKE_DIRECTORY ${EXE_DIR})
file(MAKE_DIRECTORY ${ARCH_DIR})
file(MAKE_DIRECTORY ${PDB_DIR})
file(MAKE_DIRECTORY ${PKG_OUTPUT_DIR})

set (CMAKE_LIBRARY_OUTPUT_DIRECTORY ${LIB_DIR})
set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ${EXE_DIR})
set (CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${ARCH_DIR})
set (CMAKE_PDB_OUTPUT_DIRECTORY ${PDB_DIR})

IF(WIN32 AND MSVC)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Zi /FS")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF")
ENDIF()
#==============================================================================#
# identification you AddIn
SET(MYCOMPANY "MyCompany")
SET(ADN_NAME "AddInExample")
string(TIMESTAMP YEAR "%Y")
#==============================================================================#

set(SIGN_SIGNING  ON)
if (SIGN_SIGNING)
    if(APPLE)
        SET(SIGN_CERT "1C LLC") #certificate name
    elseif(WIN32)
        find_program(SIGN_BAT NAMES sign.bat HINTS ENV PATH)
        #examle sign.bat
        #signtool sign /f certificate.pfx /p password /t http://timestamp.verisign.com/scripts/timstamp.dll /v %1
        #signtool sign /fd SHA256 /f certificate.pfx /p password /tr http://sha256timestamp.ws.symantec.com/sha256/timestamp /td SHA256 /as /v %1
        if (NOT SIGN_BAT)
            find_program(SIGN_TOOL NAMES signtool.exe HINTS ENV PATH)

            if (SIGN_TOOL)
                SET(SIGN_CERT "my.pfx" CACHE FILEPATH "Certificate path" FORCE) #certificate path
                SET(SIGN_CERT_PWD "password" CACHE STRING "Password for certificate" FORCE)
                SET(SIGN_URL_SHA1 "http://timestamp.verisign.com/scripts/timstamp.dll" CACHE STRING "SHA1 timestamp url" FORCE)
                SET(SIGN_URL_SHA256 "http://sha256timestamp.ws.symantec.com/sha256/timestamp" CACHE STRING "SHA256 timestamp url" FORCE)

                SET(SIGN_SHA1 "${SIGN_TOOL}" sign /f "${SIGN_CERT}" /p "${SIGN_CERT_PWD}" /t ${SIGN_URL_SHA1} /v) 
                SET(SIGN_SHA256 "${SIGN_TOOL}" sign  sign /fd SHA256 /f "${SIGN_CERT}" /p "${SIGN_CERT_PWD}" /tr ${SIGN_URL_SHA256} /td SHA256 /as /v)
                if (NOT EXISTS ${SIGN_CERT})
                    message(WARNING "Certificate file not found. Disabled.")
                    set(SIGN_SIGNING OFF)
                endif()
            else()
                message(WARNING "Signing tools not found. Disabled.")
                set(SIGN_SIGNING OFF)
            endif()
        endif()
    endif(APPLE)
endif()
#==============================================================================#
#seting you version file
IF(EXISTS "${CMAKE_SOURCE_DIR}/AddInVersion.txt")
    FILE(STRINGS "${CMAKE_SOURCE_DIR}/AddInVersion.txt" APP_VERSION LIMIT_COUNT 1)
ELSE()
    SET(APP_VERSION 01)
ENDIF()
SET(Addn_VERSION ${APP_VERSION} CACHE STRING "Version of external component" )
SET(ADDNVER "${Addn_VERSION}")
set(Addn_VERSION_FULL
    "${Addn_VERSION_MAJOR}.${Addn_VERSION_MINOR}.${Addn_VERSION_BUILD}.${Addn_VERSION}" CACHE 
    STRING "Full version of external component")
STRING(REPLACE "." "," Addn_VERSION_FULL_C ${Addn_VERSION_FULL})
STRING(REPLACE "." "_" Addn_VERSION_FULL_U ${Addn_VERSION_FULL})
#==============================================================================#

#==============================================================================#
#seting projects names
IF (NOT Addn_Native)
    SET(Addn_Native "AddInNative" CACHE STRING "Name for NativeAPI project" )
ENDIF()
IF (NOT Addn_Chrome)
    SET(Addn_Chrome "AddInChr" CACHE STRING "Name for Chrome adapter project" )
ENDIF()
IF (NOT Addn_IE)
    SET(Addn_IE "AddInIE" CACHE STRING "Name for IE adapter project" )
ENDIF()
IF (NOT Addn_ChromeSetup)
    SET(Addn_ChromeSetup "AddInChromeSetup" CACHE STRING "Name for Chrome Setup project" )
ENDIF()
IF (NOT Addn_IESetup)
    SET(Addn_IESetup "AddInIESetup" CACHE STRING "Name for IE Setup project" )
ENDIF()
IF (NOT Addn_COM)
    SET(Addn_COM "AddInCOM" CACHE STRING "Name for COM project" )
ENDIF()
IF (NOT Addn_Mainfest)
    SET(Addn_Mainfest "com.mycompany.enterprise.addin.example" CACHE STRING "Name of manifest for Chrome and Firefox" )
ENDIF()
IF (NOT Addn_MimeType)
    SET(Addn_MimeType "application/component-example-1" CACHE STRING "MIMEType for NPAPI project" )
ENDIF()
#==============================================================================#
SET(MIMETYPE ${Addn_MimeType})
SET(ADDNCHROME ${Addn_Chrome})
SET(ADDNNATIVE ${Addn_Native})
SET(ADDNIE ${Addn_IE})

CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/conf_data_in/AddInVersion.h.in ${CMAKE_SOURCE_DIR}/AddInVersion.h @ONLY)
CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/conf_data_in/MANIFEST.XML.in ${PKG_OUTPUT_DIR}/MANIFEST.XML @ONLY)

UNSET(MIMITYPE)
UNSET(ADDNCHROME)
UNSET(ADDNNATIVE)
UNSET(ADDNIE)
include_directories(${CMAKE_SOURCE_DIR})

if(UNIX AND NOT APPLE)
    SET(CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH ON)
    find_program(STRIP NAME eu-strip HINTS ENV PATH
        DOC "eu-strip executable"
    )
    if (NOT STRIP)
        message(WARNING "eu-strip not found!")
    endif()
    
    SET(TMP_DIR ${CMAKE_BINARY_DIR}/${MySuffix2})
endif()
SET(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)

add_subdirectory (NativeAPI)
add_subdirectory (AddInChrome)
add_subdirectory (AddInChromeSetup)

if (WIN32)
    add_subdirectory(AddInIE)
    add_subdirectory(COM)
    add_subdirectory(AddInIESetup)
endif (WIN32)
