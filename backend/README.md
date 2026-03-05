# DeskCare 服务端项目文档

## 1. 项目简介

DeskCare 服务端项目集成了 Python FastAPI 后端服务与 React 前端官网，旨在提供一站式的后端支持、数据统计及官网展示功能。

*   **项目根目录**: `DeskCare/`
*   **前端部分**: `frontend/` (React + Vite)
*   **后端部分**: `backend/` (FastAPI + SQLite)

## 2. 目录结构

```
DeskCare/
├── frontend/           # 官网前端项目 (React + Vite)
│   ├── src/            # 前端源码
│   ├── public/         # 静态资源
│   ├── package.json    # 前端依赖
│   └── vite.config.js  # 构建配置
├── backend/            # Python 后端服务 (FastAPI)
│   ├── app/            # 应用核心代码
│   ├── files/          # 存放安装包和版本信息
│   ├── static/         # 存放前端构建产物 (自动生成)
│   ├── requirements.txt# 后端依赖
│   └── run.py          # 本地启动脚本
├── releases/           # [新增] 存放打包好的安装包 (DeskCare_vX.X.X.zip)
├── deploy_full.py      # 【核心】全自动化部署脚本
├── deploy_backend.bat  # [快捷] 仅部署后端
├── deploy_frontend.bat # [快捷] 仅部署官网
├── one_click_package.bat # [快捷] 一键构建+打包+发布
├── version_info.json   # 全局版本控制文件
└── ...
```

## 3. 详细功能与 API 接口说明

### 3.1 官网访问统计 (Analytics)
后端会自动记录官网的访问日志，用于生成数据看板。

*   **接口地址**: `GET /analytics/visit`
*   **功能**: 记录一次页面访问 (PV)。
*   **参数**: 无 (自动从 HTTP Header 获取 IP, User-Agent, Referer)。
*   **后台逻辑**:
    *   解析 User-Agent 获取操作系统 (OS)、浏览器、设备类型 (PC/Mobile)。
    *   通过 IP 地址解析地理位置 (GeoIP)。
    *   记录来源 (Referrer) 以分析流量入口。
*   **前端调用**: 官网首页加载时自动调用此接口。

### 3.2 客户端活跃度上报 (DAU)
用于统计 DeskCare 软件的日活跃用户数。

*   **接口地址**: `GET /analytics/report` (兼容旧版 `/api/report`)
*   **参数**:
    *   `uid`: 机器唯一标识码 (Machine ID)。
    *   `ver`: 当前软件版本号。
*   **功能**: 记录每日首次启动，生成 DAU 报表。

### 3.3 软件下载与鉴权
控制软件安装包的下载，支持生成下载秘钥。

*   **下载接口**: `GET /download/{key}`
    *   **功能**: 验证秘钥有效性，记录下载日志，返回安装包文件。
    *   **参数**: `key` (下载秘钥)。
*   **生成秘钥 (Admin)**: `POST /download/generate_key`
    *   **参数**: `admin_secret` (管理密钥), `count` (生成数量)。

### 3.4 软件自动更新
客户端启动时检查是否有新版本。

*   **接口地址**: `GET /updates/version.json`
*   **功能**: 返回最新版本信息。
*   **返回格式**:
    ```json
    {
        "version": "1.0.7",
        "changelog": "更新日志内容...",
        "download_url": "http://server/files/DeskCare_v1.0.7.zip"
    }
    ```

### 3.5 云端配置备份
允许用户上传和恢复软件配置。

*   **上传**: `POST /backup/upload`
*   **恢复**: `GET /backup/restore?uid={uid}`

### 3.6 数据监控看板 (Dashboard)
全中文的可视化后台，无需额外账号，通过 Secret 访问。

*   **访问地址**: `/admin/dashboard?secret=TraeAdmin2026`
*   **功能**:
    *   实时 PV/UV 统计。
    *   近7天流量趋势图。
    *   用户地理分布、设备分布饼图。
    *   实时详细访问日志表格。

## 4. 自动化部署与运维

本项目已实现工业级的自动化部署流程，无需手动上传文件或执行命令。

### 4.1 部署准备
1.  **服务器**: 准备一台 Ubuntu/Debian 服务器。
2.  **配置**: 修改 `deploy_full.py` 中的服务器信息：
    ```python
    HOST = "47.101.52.0"
    USER = "root"
    PASS = "YourPassword"
    ```
3.  **本地环境**:
    *   Python 3.8+ (安装 `paramiko`: `pip install paramiko`)
    *   Node.js & npm (用于构建前端)

### 4.2 常用部署操作 (推荐)

*   **修改了 Python 后端代码？**
    *   双击运行 `deploy_backend.bat`。
    *   脚本会自动上传代码并重启远程服务。

*   **修改了官网文案或样式？**
    *   双击运行 `deploy_frontend.bat`。
    *   脚本会自动编译 React 项目并发布到服务器。

*   **发布新版本 DeskCare 软件？**
    *   双击运行 `one_click_package.bat`。
    *   脚本会自动完成以下全流程：
        1.  版本号自增 (可选)
        2.  调用 Qt 编译器构建 C++ 项目
        3.  打包生成 ZIP 文件到 `releases/` 目录
        4.  自动上传最新安装包到服务器
        5.  同步更新服务器上的版本信息 (`version_info.json`)

### 4.3 高级部署命令
如果需要更细粒度的控制，可以在命令行运行 `deploy_full.py`：

```bash
# 全量部署 (前端+后端+安装包)
python deploy_full.py all

# 仅部署后端
python deploy_full.py backend

# 仅部署前端
python deploy_full.py frontend

# 仅发布安装包 (需 releases/ 目录下有 zip 包)
python deploy_full.py app
```

## 5. 远程服务维护

在 `backend/` 目录下，提供了一套远程维护脚本，方便您在本地直接控制云端服务：

*   `service_start.bat`: 启动服务
*   `service_stop.bat`: 停止服务
*   `service_restart.bat`: 重启服务
*   `service_status.bat`: 查看运行状态
*   `service_logs.bat`: 实时查看服务器上的最后 50 行日志

## 6. 本地开发指南

### 6.1 启动后端
```bash
cd backend
pip install -r requirements.txt
python run.py
```
后端服务地址: `http://localhost:8000`

### 6.2 启动前端
```bash
cd frontend
npm install
npm run dev
```
前端开发地址: `http://localhost:5173`
