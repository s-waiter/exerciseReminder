$ErrorActionPreference = "Continue"

# 强制使用 UTF-8 输出
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=== ExerciseReminder 打包程序 ===" -ForegroundColor Cyan

# 1. 定义路径
$windeployqt = "D:\Qt\5.15.2\msvc2015_64\bin\windeployqt.exe"
$projectDir = $PSScriptRoot
$buildDirName = "Desktop_Qt_5_15_2_MSVC2015_64bit-Release" 
$releaseDir = Join-Path $projectDir "build\$buildDirName\release"
$exePath = Join-Path $releaseDir "ExerciseReminder.exe"
$distDir = Join-Path $projectDir "dist_release"
$qmlDir = Join-Path $projectDir "assets\qml"

Write-Host "工作目录: $projectDir"
Write-Host "查找 EXE: $exePath"

# 2. 详细检查 EXE
if (-not (Test-Path $exePath)) {
    Write-Host "`n[严重错误] 找不到可执行文件！" -ForegroundColor Red
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "我们检查了文件夹: $releaseDir"
    
    if (Test-Path $releaseDir) {
        $files = Get-ChildItem $releaseDir
        if ($files.Count -eq 0) {
            Write-Host "-> 这个文件夹是空的。" -ForegroundColor White
        } else {
            Write-Host "-> 这个文件夹里只有这些文件 (没有 .exe):" -ForegroundColor White
            $files | ForEach-Object { Write-Host "   $($_.Name)" -ForegroundColor Gray }
        }
    } else {
        Write-Host "-> 这个文件夹甚至不存在。" -ForegroundColor White
    }
    
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "`n[解决方案]" -ForegroundColor Green
    Write-Host "您必须先在 Qt Creator 中手动构建项目："
    Write-Host "1. 打开 Qt Creator"
    Write-Host "2. 确认左下角选择了 'Release' (不是 Debug)"
    Write-Host "3. 点击左下角的 '锤子' 图标 (构建)"
    Write-Host "4. 等待右下角的进度条完全变绿"
    Write-Host "5. 再次运行此脚本"
    
    Read-Host "`n按回车键退出..."
    exit 1
}

# 3. 准备输出目录
try {
    Write-Host "`n准备发布目录..."
    if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force -ErrorAction Stop }
    New-Item -ItemType Directory -Path $distDir -ErrorAction Stop | Out-Null
    
    Write-Host "复制主程序..."
    Copy-Item $exePath -Destination $distDir -ErrorAction Stop
}
catch {
    Write-Error "文件操作失败: $_"
    Read-Host "按回车键退出..."
    exit 1
}

# 4. 运行 windeployqt
Write-Host "运行 Qt 依赖部署工具..."
if (-not (Test-Path $windeployqt)) {
    Write-Error "找不到 windeployqt.exe，请检查 Qt 安装路径。"
    Read-Host "按回车键退出..."
    exit 1
}

$targetExe = Join-Path $distDir "ExerciseReminder.exe"
$process = Start-Process -FilePath $windeployqt -ArgumentList "--qmldir `"$qmlDir`" `"$targetExe`" --release --no-translations" -PassThru -NoNewWindow -Wait

if ($process.ExitCode -ne 0) {
    Write-Error "windeployqt 失败，退出代码: $($process.ExitCode)"
    Read-Host "按回车键退出..."
    exit 1
}

Write-Host "`n[成功] 打包完成！" -ForegroundColor Green
Write-Host "程序位于: $distDir"
Invoke-Item $distDir
Read-Host "按回车键退出..."
