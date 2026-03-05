@echo off
cd /d "%~dp0"

echo.
echo ====================================================================
echo   WARNING: DELETE ALL DATA - REMOTE (ALIYUN) DATABASE
echo ====================================================================
echo.
echo This script will TRUNCATE all tables in the REMOTE 'deskcare' database.
echo All user data, logs, and analytics on the server will be PERMANENTLY LOST.
echo.

set /p confirm="Are you sure you want to proceed? (y/N): "
if /i not "%confirm%"=="y" goto end

set /p confirm2="Confirm again: Delete ALL REMOTE data? (y/N): "
if /i not "%confirm2%"=="y" goto end

echo.
echo [EXEC] Cleaning Remote Database...
"D:\jinzhan\Software\code\anaconda3\python.exe" remote_clean.py

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to clean remote database.
) else (
    echo.
    echo [SUCCESS] Remote database cleaned and service restarted.
)

pause
goto :eof

:end
echo Operation canceled.
pause
