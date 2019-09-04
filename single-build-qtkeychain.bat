@echo off
setlocal EnableDelayedExpansion
cls

echo "*** Build: qtkeychain (%~nx0)"

Rem ******************************************************************************************
rem 			"environment Variables"
Rem ******************************************************************************************

call "%~dp0/common.inc.bat" %1 %2

Rem ******************************************************************************************

if "%TAG%" == "" set TAG=%TAG_QTKEYCHAIN%

set MY_REPO=%PROJECT_PATH%/qtkeychain
set MY_BUILD_PATH=%MY_REPO%/build
set MY_INSTALL_PATH=%PROJECT_PATH%/libs/%BUILD_TYPE%/qtkeychain/%BUILD_ARCH%

echo "* BUILD_TYPE=%BUILD_TYPE%"
echo "* BUILD_ARCH=%BUILD_ARCH%"
echo "* CMAKE_GENERATOR=%CMAKE_GENERATOR%"
echo "* CMAKE_EXTRA_FLAGS_QTKEYCHAIN=%CMAKE_EXTRA_FLAGS_QTKEYCHAIN%"
echo "* PROJECT_PATH=%PROJECT_PATH%"

echo "* QT_PATH=%QT_PATH%"
echo "* QT_BIN_PATH=%QT_BIN_PATH%"

echo "* TAG %TAG%"

echo "* MY_REPO=%MY_REPO%"
echo "* MY_BUILD_PATH=%MY_BUILD_PATH%"
echo "* MY_INSTALL_PATH=%MY_INSTALL_PATH%"

echo "* PATH=%PATH%"

Rem ******************************************************************************************
rem 			"check for required environment variables"
Rem ******************************************************************************************

call :testEnv PROJECT_PATH
call :testEnv BUILD_TYPE
call :testEnv BUILD_ARCH
call :testEnv CMAKE_GENERATOR
call :testEnv QT_PATH
call :testEnv QT_BIN_PATH
call :testEnv TAG

if %ERRORLEVEL% neq 0 goto onError

Rem ******************************************************************************************
rem 			"Test run?"
Rem ******************************************************************************************

if "%TEST_RUN%" == "1" (
    echo "** TEST RUN - exit."
    exit
)

Rem ******************************************************************************************
rem 			"clean up"
Rem ******************************************************************************************

echo "* Remove old installation files %MY_INSTALL_PATH% from previous build."
start "rm -rf" /B /wait rm -rf "%MY_INSTALL_PATH%/"*
if %ERRORLEVEL% neq 0 goto onError

echo "* Remove %MY_BUILD_PATH%/CMakeFiles from previous build."
start "rm -rf" /B /wait rm -rf "%MY_BUILD_PATH%/"*
if %ERRORLEVEL% neq 0 goto onError

Rem ******************************************************************************************
rem 			"git pull, build, collect dependencies"
Rem ******************************************************************************************

rem Reference: https://ss64.com/nt/setlocal.html
rem Reference: https://ss64.com/nt/start.html

echo "* git pull at %MY_REPO%/."
start "git pull" /D "%MY_REPO%/" /B /wait git pull --tags
if %ERRORLEVEL% neq 0 goto onError

echo "* git checkout %TAG% at %MY_REPO%/."
start "git checkout %TAG%" /D "%MY_REPO%/" /B /wait git checkout %TAG%
if %ERRORLEVEL% neq 0 goto onError

echo "* save git HEAD commit hash from repo %MY_REPO%/."
start "git rev-parse HEAD" /D "%MY_REPO%/" /B /wait git rev-parse HEAD > "%PROJECT_PATH%"/tmp
if %ERRORLEVEL% neq 0 goto onError
set /p GIT_REVISION= < "%PROJECT_PATH%"\tmp
if %ERRORLEVEL% neq 0 goto onError
del "%PROJECT_PATH%"\tmp

echo "* Run cmake with CMAKE_INSTALL_PREFIX and CMAKE_BUILD_TYPE set at %MY_BUILD_PATH%."
start "cmake.." /D "%MY_BUILD_PATH%" /B /wait cmake "-G%CMAKE_GENERATOR%" .. -DCMAKE_INSTALL_PREFIX="%MY_INSTALL_PATH%" -DCMAKE_BUILD_TYPE="%BUILD_TYPE%" %CMAKE_EXTRA_FLAGS_QTKEYCHAIN%
if %ERRORLEVEL% neq 0 goto onError

echo "* Run cmake to compile and install."
start "cmake build" /D "%MY_BUILD_PATH%" /B /wait cmake --build . --config %BUILD_TYPE% --target install
if %ERRORLEVEL% neq 0 goto onError

echo "* Copy qt5keychain.dll to %QT_BIN_PATH%/ for windeployqt to find it."
start "copy qt5keychain.dll for windeployqt" /B /wait cp -f "%MY_INSTALL_PATH%/bin/qt5keychain.dll" "%QT_BIN_PATH%/"
if %ERRORLEVEL% neq 0 goto onError

Rem ******************************************************************************************

echo "*** Finished Build: qtkeychain %BUILD_TYPE% %BUILD_ARCH% (GIT_REVISION=%GIT_REVISION%) (%~nx0)"
exit 0

:onError
echo "*** Build FAILED: qtkeychain %BUILD_TYPE% %BUILD_ARCH% (%~nx0)"
if %ERRORLEVEL% neq 0 exit %ERRORLEVEL%
if !ERRORLEVEL! neq 0 exit !ERRORLEVEL!
exit 1

:testEnv
if "!%*!" == "" (
    echo "Missing environment variable: %*"
    exit /B 1
)
exit /B