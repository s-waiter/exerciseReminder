# DeskCare 在线自动更新技术方案 (Auto-Update Technical Proposal)

## 1. 方案概述 (Overview)

本方案旨在为 **DeskCare** 增加基于 HTTP 的自动检查与更新功能。利用现有的阿里云 Nginx 服务器托管更新配置文件 (`version.json`) 和安装包 (`.zip`)。客户端通过轮询或用户触发的方式检查更新，并采用**独立更新程序 (Updater)** 的模式实现无缝覆盖安装，确保用户体验流畅且界面美观。

## 2. 架构设计 (Architecture)

### 2.1 服务端 (Server Side)
- **基础设施**：现有阿里云服务器 (Nginx)。
- **目录结构**：
  在 `/var/www/deskcare/` 下新增 `updates` 目录：
  ```text
  /var/www/deskcare/updates/
  ├── version.json        # 版本控制文件 (核心)
  ├── DeskCare_v1.1.0.zip # 最新版完整包
  ├── DeskCare_v1.0.5.zip # 历史版本
  └── ...
  ```
- **version.json 协议定义**：
  ```json
  {
    "latest_version": "1.1.0",
    "release_date": "2026-02-15",
    "download_url": "http://47.101.52.0/updates/DeskCare_v1.1.0.zip",
    "changelog": "1. 新增在线更新功能\n2. 优化内存占用",
    "min_supported_version": "1.0.0",  // 低于此版本强制更新
    "file_hash": "a1b2c3d4..."         // SHA256，用于校验文件完整性 (可选)
  }
  ```

### 2.2 客户端 (Client Side)
客户端分为两个部分：
1.  **DeskCare 主程序**：负责检查更新、下载文件、提示用户。
2.  **Updater 工具 (独立 EXE)**：负责在主程序关闭后，解压覆盖文件，并重启主程序。

> **为什么需要独立的 Updater？**
> Windows 操作系统禁止修改正在运行的可执行文件。因此，主程序无法“自己更新自己”。必须先退出主程序，由另一个进程完成文件覆盖，再重新启动主程序。

## 3. 详细交互流程 (Workflow)

### 阶段一：检查更新 (Check)
1.  **触发**：软件启动时自动检查，或用户点击“设置 -> 检查更新”。
2.  **请求**：主程序发起 `GET http://47.101.52.0/updates/version.json` 请求。
3.  **比较**：
    - 读取本地版本 (定义在 `AppConfig` 或 `version.h`，如 `1.0.0`)。
    - 比较 `remote.latest_version > local.current_version`。
4.  **反馈**：
    - **无更新**：提示“当前已是最新版本”。
    - **有更新**：弹出自定义 UI 对话框，显示 `changelog`，提供【立即更新】和【稍后提醒】按钮。

### 阶段二：下载更新 (Download)
1.  **下载**：用户点击【立即更新】后，主程序下载 ZIP 包到临时目录 (如 `%TEMP%/DeskCare_Update.zip`)。
2.  **进度**：在主界面显示下载进度条。
3.  **校验**：下载完成后，可选校验文件 Hash 值。

### 阶段三：安装更新 (Install)
1.  **准备**：下载完成后，主程序释放/启动 `Updater.exe`，并传入参数：
    - 参数1：`source_zip_path` (更新包路径)
    - 参数2：`target_dir` (安装目录)
    - 参数3：`executable_name` (重启的程序名，如 DeskCare.exe)
2.  **退出**：主程序主动调用 `QCoreApplication::quit()` 退出。
3.  **覆盖**：
    - `Updater.exe` 启动，显示一个小窗口“正在安装更新...”。
    - 等待 `DeskCare.exe` 进程完全结束。
    - 调用系统解压命令 (或内置解压库) 将 ZIP 包内容覆盖到安装目录。
4.  **重启**：更新完成后，`Updater.exe` 启动 `DeskCare.exe`，然后自我关闭。

## 4. 技术选型与实现细节

### 4.1 Updater 实现方式
为了保持“精美 UI”的原则，建议 **使用 Qt 编写一个极简的 Updater 程序**，而不是使用丑陋的 CMD 批处理脚本。
- **UI**：无边框窗口，包含应用 Logo、进度条、状态文字。
- **解压逻辑**：
  - **方案 A (推荐 - 零依赖)**：使用 Windows 内置 PowerShell 命令解压：
    `powershell -command "Expand-Archive -Path 'src.zip' -DestinationPath 'dst' -Force"`
  - **方案 B (高性能)**：引入 `zlib` 或 `miniz` 库进行解压 (开发成本略高)。

### 4.2 目录结构调整
发布包结构将变为：
```text
DeskCare/
├── DeskCare.exe
├── Updater.exe      <-- 新增
├── ... (dlls)
```

## 5. 开发计划 (Development Plan)

1.  **服务端准备**：
    - 在阿里云服务器创建目录。
    - 配置 Nginx 允许下载 zip 和 json。
    - 编写发布脚本，自动生成 `version.json`。

2.  **开发 Updater 工具**：
    - 创建新的 Qt Console 或 Widget 项目。
    - 实现进程等待、文件解压、进程启动逻辑。

3.  **改造主程序**：
    - 集成 `NetworkManager` 请求版本信息。
    - 实现下载逻辑和进度显示 UI。
    - 实现启动 Updater 并退出的逻辑。

4.  **测试验证**：
    - 模拟版本升级，测试覆盖安装是否成功。
    - 测试网络异常、权限不足等边缘情况。

## 6. 优势总结
- **用户体验好**：全程无感，无黑框，UI 风格统一。
- **维护简单**：服务端只需上传文件和修改 JSON。
- **扩展性强**：未来可支持强制更新、灰度发布等功能。
