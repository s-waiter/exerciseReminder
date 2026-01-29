@echo off
echo 正在启动打包脚本...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_release.ps1"
if %errorlevel% neq 0 (
    echo.
    echo 脚本启动失败，请确认 deploy_release.ps1 存在。
    pause
)
