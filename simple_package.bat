@echo off
chcp 65001 >nul
echo ==========================================
echo      ExerciseReminder 极简打包脚本
echo ==========================================
echo.

set "EXE_PATH=build\Desktop_Qt_5_15_2_MSVC2015_64bit-Release\release\ExerciseReminder.exe"
set "QT_TOOL=D:\Qt\5.15.2\msvc2015_64\bin\windeployqt.exe"

if not exist "%EXE_PATH%" (
    echo [错误] 找不到文件: %EXE_PATH%
    echo 请先在 Qt Creator 中构建 Release 版本！
    pause
    exit /b
)

echo 1. 清理旧目录...
rmdir /s /q dist_release 2>nul
mkdir dist_release

echo 2. 复制程序...
copy "%EXE_PATH%" dist_release\

echo 3. 部署依赖...
"%QT_TOOL%" --qmldir assets\qml dist_release\ExerciseReminder.exe --release --no-translations

echo.
echo [成功] 打包完成！
echo 文件夹: %~dp0dist_release
echo.
pause
