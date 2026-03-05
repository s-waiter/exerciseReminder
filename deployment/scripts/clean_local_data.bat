@echo off
cd /d "%~dp0"

echo.
echo ====================================================================
echo   WARNING: DELETE ALL DATA - LOCAL DATABASE
echo ====================================================================
echo.
echo This script will TRUNCATE all tables in the LOCAL 'deskcare' database.
echo All user data, logs, and analytics will be PERMANENTLY LOST.
echo.

set /p confirm="Are you sure you want to proceed? (y/N): "
if /i not "%confirm%"=="y" goto end

set /p confirm2="Confirm again: Delete ALL LOCAL data? (y/N): "
if /i not "%confirm2%"=="y" goto end

echo.
echo [EXEC] Cleaning Local Database...
"D:\jinzhan\Software\code\anaconda3\python.exe" clean_db.py

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to clean database.
) else (
    echo.
    echo [SUCCESS] Local database cleaned.
    echo NOTE: Please restart your local backend service to recreate the default admin user.
)

pause
goto :eof

:end
echo Operation canceled.
pause
