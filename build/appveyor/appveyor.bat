setlocal
@echo ON

cd %APPVEYOR_BUILD_FOLDER%
mkdir -p tmp
cd tmp

:: get version label
appveyor DownloadFile http://ci.roessler.systems/files/qt-bin/UnxUtils.zip -Filename UnxUtils.zip
7z x UnxUtils.zip
cp usr\local\wbin\date.exe .

cd ..

git describe --exact-match HEAD
if %ERRORLEVEL% == 0 (
    SET release=1
) else (
    SET release=0
)
if %release% == 0 (
    for /f %%i in ('tmp\date.exe -u +"%%Y%%m%%d%%H%%M"') do set datetime=%%i

    ::for /f %%i in ('git rev-parse --abbrev-ref HEAD') do set branch=%%i
    set branch=%APPVEYOR_REPO_BRANCH%

    for /f %%i in ('git rev-parse --short HEAD') do set revision=%%i
) else (
    for /f %%i in ('git describe --tags') do set version=%%i
)

if %release% == 0 (
    set version=%datetime%-%branch%-%revision%
)
echo #define REVISION "%version%" > src\revision.h
appveyor UpdateBuild -Version "%version%-%ARCH%"

:: download and install QtQuickVcp
appveyor DownloadFile https://dl.bintray.com/machinekoder/QtQuickVcp-Development/QtQuickVcp_Development-latest-Windows-%ARCH%.zip -Filename QtQuickVcp.zip
7z x QtQuickVcp.zip
cp lib\libzmq.dll %QTDIR%\lib\
mv lib\libzmq.dll %QTDIR%\lib\
cp -r qml\Machinekit %QTDIR%\qml\

:: start build
cd %APPVEYOR_BUILD_FOLDER%
mkdir build.release
cd build.release
qmake ..
nmake

SET PACKAGENAME=QmlLiveBench
SET TARGETNAME=qmllivebench
SET QMLDIR=src/bench
SET APPDIR=bin
SET LIBDIR=lib
mkdir %PACKAGENAME%
cd %PACKAGENAME%
cp ../%APPDIR%/%TARGETNAME%.exe .
cp ../%LIBDIR%/qmllive1.dll .
cp %QTDIR%\lib\libzmq.dll .
windeployqt --angle --release --qmldir ../../%QMLDIR%/ %TARGETNAME%.exe
cd ..
7z a %PACKAGENAME%.zip %PACKAGENAME%/

:: rename deployment files
set platform=%ARCH%
if %release% == 0 (
    set target="%PACKAGENAME%_Development"
) else (
    set target="%PACKAGENAME%"
)

mv %PACKAGENAME%.zip %target%-%version%-%platform%.zip

goto :EOF

:error
echo Failed!
EXIT /b %ERRORLEVEL%
