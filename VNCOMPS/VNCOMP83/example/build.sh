#!/bin/bash

#build script

PATH=~/bin:$PATH
set -e

ARCH_NAME=example.zip
ARCH_OSX=mac.pkg.zip
ARCH_LIN=lin.pkg.zip
ARCH_WIN=win.pkg.zip

cmake -E remove_directory ./bin
cmake -E remove_directory ./pkg
cmake -E remove_directory ./debug_info
cmake -E remove_directory ./binsh
export OS=`uname`
if [ $OS = "Darwin" ]; then
    cmake -E remove_directory MacBuild
    cmake -E make_directory MacBuild
    cmake -E make_directory bin
    pushd MacBuild
    cmake -D CMAKE_BUILD_TYPE:STRING=Release -D TARGET_PLATFORM_32:BOOL=OFF -DCMAKE_OSX_SYSROOT=macosx .. 
    cmake --build .
    popd
    cmake -E remove_directory MacBuild
    pushd pkg
    ls -A > ../flist.lst
    cmake -E tar cf ../$ARCH_OSX --format=zip --files-from=../flist.lst
    cmake -E remove -f ../flist.lst
    popd

    cmake -E tar cjf mac.bin.tar.bz2 bin/ debug_info/

    if [[ -f $ARCH_LIN && -f $ARCH_WIN ]]; then
        cmake -E echo Make zip-archive
        pushd pkg
        cmake -E tar xf ../$ARCH_WIN
        cmake -E tar xf ../$ARCH_LIN
        ls -A > ../flist.lst
        cmake -E tar cf ../$ARCH_NAME --format=zip --files-from=../flist.lst
        popd
        cmake -E remove -f flist.lst
        cmake -E remove $ARCH_WIN
        cmake -E remove $ARCH_LIN
    fi
    exit
fi

cmake -E echo "Build 64"
cmake -E remove_directory build64
cmake -E make_directory build64
cd build64 ;
cmake -D CMAKE_BUILD_TYPE:STRING=Release -D TARGET_PLATFORM_32:BOOL=OFF .. ;
cmake --build . -- -j 2
cd ..
cmake -E remove_directory build64

cmake -E echo "Build 32"
cmake -E remove_directory build32
cmake -E make_directory build32
cd build32
cmake -D CMAKE_BUILD_TYPE:STRING=Release -D TARGET_PLATFORM_32:BOOL=ON .. ;
cmake --build . -- -j 2
cd ..
cmake -E remove_directory build32

cd pkg
ls -A > ../flist.lst
cmake -E tar cf ../$ARCH_LIN --format=zip --files-from=../flist.lst
cmake -E remove -f ../flist.lst
cd ..

cmake -E tar cjf lin.bin.tar.bz2 bin/ debug_info/

if [[ -f $ARCH_OSX && -f $ARCH_WIN ]]; then
    cmake -E echo Make zip-archive
    cd pkg
    cmake -E tar xf ../$ARCH_WIN
    cmake -E tar xf ../$ARCH_OSX
    ls -A > ../flist.lst
    cmake -E tar cf ../$ARCH_NAME --format=zip --files-from=../flist.lst
    cd ..
    cmake -E remove -f flist.lst
    cmake -E remove $ARCH_WIN
    cmake -E remove $ARCH_OSX
fi
