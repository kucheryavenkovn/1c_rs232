@echo off

cmake -E echo Set Visual Studio version and toolset
SET VS_VER=15
SET VS_YEAR=2017
SET VS_TOOLSET=v141_xp
SET BUILD_CONFIG=Release

SET ARCH_NAME=example.zip
SET ARCH_OSX=mac.pkg.zip
SET ARCH_LIN=lin.pkg.zip
SET ARCH_WIN=win.pkg.zip

cmake -E remove_directory ./bin
cmake -E remove_directory ./debug_info
cmake -E remove_directory ./pkg
cmake -E remove_directory ./binsh
cmake -E remove -f %ARCH_NAME%

cmake -E echo "Build 64"
cmake -S . -B build64 -G "Visual Studio %VS_VER% %VS_YEAR%" -A x64 -DCMAKE_BUILD_TYPE=%BUILD_CONFIG% -DCMAKE_GENERATOR_TOOLSET=%VS_TOOLSET%
if ERRORLEVEL 1 goto :FailConfig

cmake --build build64 --config %BUILD_CONFIG%
if ERRORLEVEL 1 goto :Fail
cmake -E remove_directory build64

cmake -E echo "Build 32"
cmake -S . -B build32 -G "Visual Studio %VS_VER% %VS_YEAR%" -A Win32 -DCMAKE_BUILD_TYPE=%BUILD_CONFIG% -DCMAKE_GENERATOR_TOOLSET=%VS_TOOLSET%
if ERRORLEVEL 1 goto :FailConfig

cmake --build build32 --config %BUILD_CONFIG%
if ERRORLEVEL 1 goto :Fail
cmake -E remove_directory build32
pushd pkg
dir /B > ../flist.lst
cmake -E tar cf ../%ARCH_WIN% --format=zip --files-from=../flist.lst
popd
cmake -E remove -f flist.lst
cmake -E tar cjf win.bin.tar.bz2 bin/ debug_info/

IF EXIST %ARCH_LIN% (
    IF EXIST %ARCH_OSX% (
        cmake -E echo Make zip-archive
        pushd pkg
        cmake -E tar xf ../%ARCH_OSX% 
        cmake -E tar xf ../%ARCH_LIN% 
        dir /B > ../flist.lst
        cmake -E tar cf ../%ARCH_NAME% --format=zip --files-from=../flist.lst
        popd
        cmake -E remove -f flist.lst
        cmake -E remove %ARCH_OSX%
        cmake -E remove %ARCH_LIN%
    )
)

exit /B 0
:FailConfig
cmake -E echo ---------------------------------------------------
cmake -E echo Error configure targets
exit /B 1
:Fail
cmake -E echo ---------------------------------------------------
cmake -E echo Error building targets
exit /B 1
