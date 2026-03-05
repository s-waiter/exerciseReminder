@echo off
setlocal EnableDelayedExpansion

:: Change to script directory
cd /d "%~dp0"
:: Go to project root (one level up)
cd ..

:: 0. Interactive Menu
echo ========================================================
echo             DeskCare Deployment Manager
echo ========================================================
echo.
echo Please select an action:
echo 1. Deploy Backend (Python API)
echo 2. Deploy Frontend (Official Website)
echo 3. Package and Deploy App (Installer)
echo 4. Deploy ALL (Full Stack Update)
echo 5. Exit
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto deploy_backend
if "%choice%"=="2" goto deploy_frontend
if "%choice%"=="3" goto deploy_app
if "%choice%"=="4" goto deploy_all
if "%choice%"=="5" goto end

echo Invalid choice.
pause
goto end

:deploy_backend
echo.
echo [DEPLOY] Starting Backend Deployment...
"D:\jinzhan\Software\code\anaconda3\python.exe" deployment\deploy_full.py backend
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Backend deployment failed.
    pause
) else (
    echo [SUCCESS] Backend deployment completed.
)
pause
goto end

:deploy_frontend
echo.
echo [DEPLOY] Starting Frontend Deployment...
"D:\jinzhan\Software\code\anaconda3\python.exe" deployment\deploy_full.py frontend
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Frontend deployment failed.
    pause
) else (
    echo [SUCCESS] Frontend deployment completed.
)
pause
goto end

:deploy_app
echo.
echo [DEPLOY] Starting App Packaging and Deployment...
call deployment\one_click_package.bat
pause
goto end

:deploy_all
echo.
echo [DEPLOY] Starting Full Stack Deployment...
echo.
echo Step 1: Backend...
"D:\jinzhan\Software\code\anaconda3\python.exe" deployment\deploy_full.py backend
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Backend deployment failed. Aborting.
    pause
    goto end
)

echo.
echo Step 2: Frontend...
"D:\jinzhan\Software\code\anaconda3\python.exe" deployment\deploy_full.py frontend
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Frontend deployment failed. Aborting.
    pause
    goto end
)

echo.
echo Step 3: App Package...
:: Note: one_click_package.bat handles its own deployment logic at the end.
:: We might want to call it with a flag or just let it run.
:: However, one_click_package.bat has a pause at the end and prompts for deployment.
:: For automation, we might need to adjust one_click_package.bat to accept an argument to skip prompt.
:: But for now, let's just call it.
call deployment\one_click_package.bat

echo.
echo [SUCCESS] Full Stack Deployment Sequence Completed.
pause
goto end

:end
exit /b
