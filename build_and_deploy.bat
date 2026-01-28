@echo off
setlocal

echo ==========================================
echo      Exercise Reminder Build & Deploy
echo ==========================================

:: 1. Check for Qt environment
where qmake >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Qt environment not found.
    echo Please run this script within a Qt Command Prompt.
    echo Example: Search for "Qt 5.15.2 (MSVC 2019 64-bit)" in Start Menu and run it.
    echo Then navigate to this folder and run build_and_deploy.bat
    pause
    exit /b 1
)

:: 2. Clean and Build Release
echo [INFO] Cleaning previous builds...
if exist Makefile (
    nmake clean >nul 2>nul
    if %errorlevel% neq 0 mingw32-make clean >nul 2>nul
)

echo [INFO] Running qmake (Release)...
qmake -config release
if %errorlevel% neq 0 (
    echo [ERROR] qmake failed.
    pause
    exit /b 1
)

echo [INFO] Compiling (this may take a while)...
:: Try nmake first (MSVC), then mingw32-make
nmake
if %errorlevel% neq 0 (
    echo [INFO] nmake failed or not found, trying mingw32-make...
    mingw32-make
    if %errorlevel% neq 0 (
        echo [ERROR] Compilation failed.
        pause
        exit /b 1
    )
)

:: 3. Prepare Deployment Directory
set "DEPLOY_DIR=ExerciseReminder_Dist"
if exist "%DEPLOY_DIR%" rmdir /s /q "%DEPLOY_DIR%"
mkdir "%DEPLOY_DIR%"

:: 4. Copy Executable
echo [INFO] Copying executable...
:: Check common release output paths
if exist "release\ExerciseReminder.exe" (
    copy "release\ExerciseReminder.exe" "%DEPLOY_DIR%\"
) else if exist "ExerciseReminder.exe" (
    copy "ExerciseReminder.exe" "%DEPLOY_DIR%\"
) else (
    echo [ERROR] Could not find compiled ExerciseReminder.exe
    pause
    exit /b 1
)

:: 5. Run windeployqt
echo [INFO] Running windeployqt to deploy dependencies...
cd "%DEPLOY_DIR%"
windeployqt --qmldir ..\assets\qml ExerciseReminder.exe
if %errorlevel% neq 0 (
    echo [WARNING] windeployqt finished with errors. Please check output.
)
cd ..

echo ==========================================
echo [SUCCESS] Deployment Complete!
echo The standalone package is located in: %CD%\%DEPLOY_DIR%
echo You can zip this folder and send it to other users.
echo ==========================================
pause
