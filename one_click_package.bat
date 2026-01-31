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
:: NOTE: If you are using a shadow build (default in Qt Creator), update this path to point to your actual build directory.
:: E.g., ..\build-DeskCare-Desktop_Qt_5_15_2_MSVC2015_64bit-Release\release
set "BUILD_DIR=%PROJECT_ROOT%\build\Desktop_Qt_5_15_2_MSVC2015_64bit-Release\release"
set "EXE_NAME=DeskCare.exe"
set "DIST_DIR=%PROJECT_ROOT%\dist"
set "QML_DIR=%PROJECT_ROOT%\assets\qml"
set "ZIP_NAME=DeskCare_v1.0.zip"

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

:: 8. Auto-Zip & Update Website
echo [STEP] Compressing and Updating Website Resources...
"C:\Users\admin\anaconda3\python.exe" package_zip.py

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Packaging failed.
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

:: 10. Auto Deploy Option
set /p DEPLOY_NOW="Do you want to deploy the new version to the website now? (Y/N): "
if /i "%DEPLOY_NOW%"=="Y" (
    echo.
    echo [DEPLOY] Starting deployment sequence...
    
    echo [DEPLOY] Building website (npm run build)...
    cd /d "%PROJECT_ROOT%\website_project\official_site"
    call npm run build
    
    echo [DEPLOY] Uploading to server...
    cd /d "%PROJECT_ROOT%\website_project"
    "C:\Users\admin\anaconda3\python.exe" deploy.py
    
    if !ERRORLEVEL! EQU 0 (
        echo.
        echo [SUCCESS] Website updated and deployed successfully!
    ) else (
        echo.
        echo [ERROR] Deployment failed.
    )
    
    cd /d "%PROJECT_ROOT%"
) else (
    echo You can deploy later by running: python website_project\deploy.py
)

echo.
pause
