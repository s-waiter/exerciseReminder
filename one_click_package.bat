@echo off
setlocal EnableDelayedExpansion

:: Change to script directory
cd /d "%~dp0"

:: 0. Version Management
echo [VERSION] Checking version...
"C:\Users\admin\anaconda3\python.exe" scripts/manage_version.py
echo.
set /p DO_BUMP="Do you want to bump the version? (Y/N): "
if /i "%DO_BUMP%"=="Y" (
    "C:\Users\admin\anaconda3\python.exe" scripts/manage_version.py bump
    if !ERRORLEVEL! NEQ 0 (
        echo [ERROR] Version bump failed.
        pause
        exit /b 1
    )
    echo [VERSION] Bumped.
)

:: 1. Setup Build Environment
echo [ENV] Setting up build environment...

:: 1.1 Visual Studio (Using VS2022 Community path found on system)
:: Note: Using MSVC 2015 compatible toolchain (amd64)
if exist "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
) else (
    echo [ERROR] Visual Studio environment file not found.
    echo Please check your VS installation path.
    pause
    exit /b 1
)

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to setup VS environment.
    pause
    exit /b 1
)

:: 1.2 Qt
set "QT_BIN_DIR=D:\Qt\5.15.2\msvc2015_64\bin"
if not exist "%QT_BIN_DIR%" (
    echo [ERROR] Qt not found at %QT_BIN_DIR%
    pause
    exit /b 1
)
set "PATH=%QT_BIN_DIR%;%PATH%"

:: 2. Build Updater
echo [BUILD] Building Updater...
cd src\updater
if exist "Makefile" nmake distclean
call qmake updater.pro
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] qmake for Updater failed.
    pause
    exit /b 1
)
call nmake release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] nmake for Updater failed.
    pause
    exit /b 1
)
cd ..\..

:: 3. Build DeskCare
echo [BUILD] Building DeskCare...
set "BUILD_ROOT=build\Desktop_Qt_5_15_2_MSVC2015_64bit-Release"
if not exist "%BUILD_ROOT%" mkdir "%BUILD_ROOT%"
cd "%BUILD_ROOT%"

:: Clean old executable to ensure we're not packaging stale file
if exist "release\DeskCare.exe" del "release\DeskCare.exe"
:: Optional: clean makefile to ensure fresh build config
if exist "Makefile" nmake distclean

call qmake "..\..\DeskCare.pro" -spec win32-msvc
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] qmake for DeskCare failed.
    pause
    exit /b 1
)
call nmake release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] nmake for DeskCare failed.
    pause
    exit /b 1
)
cd ..\..

:: 4. Prepare Dist
echo [DIST] Preparing distribution...
set "DIST_DIR=dist"
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%"

:: 5. Copy Files
echo [COPY] Copying executables...
if exist "%BUILD_ROOT%\release\DeskCare.exe" (
    copy "%BUILD_ROOT%\release\DeskCare.exe" "%DIST_DIR%" >nul
) else (
    echo [ERROR] DeskCare.exe not found in build output.
    pause
    exit /b 1
)

if exist "src\updater\release\Updater.exe" (
    copy "src\updater\release\Updater.exe" "%DIST_DIR%" >nul
) else (
    echo [ERROR] Updater.exe not found in build output.
    pause
    exit /b 1
)

:: 6. Deploy Qt Dependencies
echo [DEPLOY] Running windeployqt...
call windeployqt --qmldir "assets\qml" --no-compiler-runtime --dir "%DIST_DIR%" "%DIST_DIR%\DeskCare.exe" >nul
:: Run for Updater to ensure widgets dependencies are present
call windeployqt --no-compiler-runtime --dir "%DIST_DIR%" "%DIST_DIR%\Updater.exe" >nul

:: 7. Cleanup Junk
echo [CLEAN] Removing junk files...
del "%DIST_DIR%\*.pdb" >nul 2>nul
del "%DIST_DIR%\*.obj" >nul 2>nul
del "%DIST_DIR%\*.cpp" >nul 2>nul
del "%DIST_DIR%\*.h" >nul 2>nul

:: 8. Package Zip
echo [PACK] Creating Zip...
"C:\Users\admin\anaconda3\python.exe" package_zip.py
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Packaging failed.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Build and Packaging Completed!
echo.

:: 9. Auto Deploy Option
set /p DEPLOY_NOW="Do you want to deploy to server? (Y/N): "
if /i "%DEPLOY_NOW%"=="Y" (
    echo [DEPLOY] Starting deployment...
    "C:\Users\admin\anaconda3\python.exe" website_project/deploy.py
)

pause