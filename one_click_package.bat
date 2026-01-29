@echo off
setlocal EnableDelayedExpansion

:: ==========================================
:: One-Click Package Script
:: ==========================================

echo [INIT] Initializing environment...

:: 1. Auto-configure Qt Environment
set "QT_BIN_DIR=D:\Qt\5.15.2\msvc2015_64\bin"

if not exist "%QT_BIN_DIR%\windeployqt.exe" (
    echo [ERROR] Qt environment not found.
    echo Expected path: %QT_BIN_DIR%
    echo Please check your Qt installation.
    pause
    exit /b 1
)

:: Add Qt bin to PATH
set "PATH=%QT_BIN_DIR%;%PATH%"
echo [OK] Qt environment configured.

:: 2. Set Project Paths
cd /d "%~dp0"
set "PROJECT_ROOT=%CD%"
set "BUILD_DIR=%PROJECT_ROOT%\build\Desktop_Qt_5_15_2_MSVC2015_64bit-Release\release"
set "EXE_NAME=ExerciseReminder.exe"
set "DIST_DIR=%PROJECT_ROOT%\dist"
set "QML_DIR=%PROJECT_ROOT%\assets\qml"
set "ZIP_NAME=ExerciseReminder_v1.0.zip"

:: 3. Check Release File
echo [CHECK] Checking for executable...
if not exist "%BUILD_DIR%\%EXE_NAME%" (
    echo [ERROR] Release executable not found.
    echo Path: "%BUILD_DIR%\%EXE_NAME%"
    echo Please build the project in Release mode first.
    pause
    exit /b 1
)

:: 4. Prepare Dist Directory
echo [STEP] Cleaning and creating dist directory...
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%"

:: 5. Copy Executable
echo [STEP] Copying executable...
copy "%BUILD_DIR%\%EXE_NAME%" "%DIST_DIR%" >nul

:: 6. Run windeployqt
echo [STEP] Deploying dependencies (windeployqt)...
:: Added --no-compiler-runtime to suppress VCINSTALLDIR warning since we are not in a VS command prompt
call windeployqt --qmldir "%QML_DIR%" --no-compiler-runtime --dir "%DIST_DIR%" "%DIST_DIR%\%EXE_NAME%" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Dependency deployment failed.
    pause
    exit /b 1
)

:: 7. Clean up junk files (Optional)
del "%DIST_DIR%\*.pdb" >nul 2>nul
del "%DIST_DIR%\*.obj" >nul 2>nul
del "%DIST_DIR%\*.cpp" >nul 2>nul
del "%DIST_DIR%\*.h" >nul 2>nul

:: 8. Auto-Zip
echo [STEP] Compressing to ZIP...
if exist "%ZIP_NAME%" del "%ZIP_NAME%"
powershell -Command "Compress-Archive -Path '%DIST_DIR%\*' -DestinationPath '%ZIP_NAME%'"

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compression failed.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo [SUCCESS] Packaging Completed!
echo ==========================================
echo.
echo Generated file: %PROJECT_ROOT%\%ZIP_NAME%
echo.
echo You can now send this ZIP file to your friends.
echo.
pause
