# 在线更新功能开发与集成记录

**日期**: 2026-01-31
**任务**: 开发并集成 DeskCare 在线更新功能

## 1. 需求分析
用户希望为 DeskCare 增加在线更新功能，具体要求如下：
1.  **自动版本递增**: 打包脚本每次执行时自动增加版本号。
2.  **用户自主选择**: 有新版本时仅提醒，由用户决定是否下载安装。
3.  **手动检查**: 用户可以通过菜单手动检查更新。
4.  **自动清理**: 安装新版本时自动删除旧版本。

## 2. 技术方案
采用 **C/S 架构** + **独立更新程序** 的方案：
*   **服务端**: Nginx 托管 `version.json` 和 ZIP 更新包。
*   **客户端**:
    *   **主程序 (DeskCare.exe)**: 负责检查更新 (`UpdateManager`)，下载更新包，并启动更新程序。
    *   **更新程序 (Updater.exe)**: 独立进程，负责等待主程序退出，解压覆盖文件，并重启主程序。此设计解决了 Windows 下无法在运行时覆盖自身 exe 的文件锁问题。

## 3. 详细实现

### 3.1 版本管理系统
*   **Version.h**: 定义 C++ 宏 `APP_VERSION`。
*   **version_info.json**: 项目根目录下的单一数据源，存储当前版本号 (Major, Minor, Patch)。
*   **manage_version.py**: Python 脚本，用于读取、递增版本号，并同步更新 `Version.h` 和 `version_info.json`。

### 3.2 自动化打包脚本 (`one_click_package.bat`)
*   集成 `manage_version.py`，在编译前自动递增版本号。
*   调用 `package_zip.py`，根据当前版本号生成带版本后缀的压缩包 (如 `DeskCare_v1.0.1.zip`)。
*   确保 `Updater.exe` 被一同打包。

### 3.3 独立更新程序 (`src/updater`)
*   **UI**: 使用 Qt 构建简洁的进度窗口。
*   **解压逻辑**: 调用 PowerShell 的 `Expand-Archive` 命令进行解压，不依赖额外的解压库 (Zero-dependency)。
*   **流程**:
    1.  启动后等待 2 秒确保主程序完全退出。
    2.  执行解压命令覆盖安装目录（实现"删除旧版本"的效果）。
    3.  解压完成后重启 `DeskCare.exe`。

### 3.4 主程序集成 (`src/core`, `src/gui`)
*   **UpdateManager**:
    *   封装网络请求 (QNetworkAccessManager) 获取 `version.json`。
    *   比较本地版本与远程版本。
    *   负责下载 ZIP 文件并监控进度。
*   **TrayIcon**:
    *   新增“检查更新”菜单项。
    *   实现槽函数处理更新信号：弹出对话框告知用户新版本信息，由用户点击“立即更新”才开始下载。
    *   下载完成后自动启动 `Updater.exe` 并退出主程序。

### 3.5 部署脚本升级 (`deploy.py`)
*   自动生成 `version.json`，包含最新版本号、下载链接、更新日志等信息。
*   将生成的 ZIP 包和 `version.json` 上传至服务器 `/var/www/deskcare/updates/` 目录。
*   配置 Nginx 使得更新文件可通过 HTTP 访问。

## 4. 文件变更列表
*   `src/core/Version.h` (新建)
*   `src/core/UpdateManager.h/cpp` (新建)
*   `src/updater/main.cpp` (新建)
*   `src/updater/updater.pro` (新建)
*   `src/gui/TrayIcon.h/cpp` (修改)
*   `scripts/manage_version.py` (新建)
*   `package_zip.py` (修改)
*   `one_click_package.bat` (修改)
*   `website_project/deploy.py` (修改)
*   `website_project/deploy/setup_remote.sh` (修改)

## 5. 总结
在线更新功能已完整实现，覆盖了从版本管理、自动打包、云端部署到客户端检测、下载、覆盖安装的全链路流程。采用了独立进程更新的成熟方案，保证了更新的可靠性。
