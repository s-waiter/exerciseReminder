# DeskCare Python 后端系统说明文档

## 1. 系统简介

DeskCare 后端系统是一个基于 Python FastAPI 框架构建的高性能、轻量级服务端应用。它主要负责为 DeskCare 客户端提供API支持，同时也承载了软件官网的静态资源服务。

核心目标是提供稳定、快速的接口服务，并实现精细化的数据统计与用户行为分析。

## 2. 详细功能介绍

### 2.1 实时数据分析看板 (Admin Dashboard)
访问地址：`/admin/dashboard?secret=TraeAdmin2026` (默认密钥，请在生产环境中修改)

这是一个全中文的可视化数据监控后台，集成了 ECharts 图表库，提供以下核心指标：
*   **实时概览**：展示今日浏览量(PV)、今日访客数(UV)、历史总浏览量、总下载量及总用户数(机器ID去重)。
*   **流量趋势分析**：最近7天的 PV/UV 折线图，帮助观察流量波动。
*   **用户画像分布**：
    *   **地理位置分布**：基于 GeoIP2 库解析 IP，展示用户来源地 Top 10。
    *   **操作系统分布**：识别 Windows, macOS, Linux, iOS, Android 等。
    *   **浏览器分布**：识别 Chrome, Firefox, Safari, Edge 等。
*   **实时访问日志**：最近20条详细访问记录，包括时间、IP、设备类型(PC/Mobile)、来源(Referrer)及访问路径。

### 2.2 软件下载与版本控制
*   **下载凭证管理**：支持生成一次性或多次使用的下载密钥 (Download Key)，防止软件被滥用下载。
*   **自动版本检测**：客户端启动时自动请求 `/updates/version.json`，后端返回最新版本号及更新日志，支持强制更新。
*   **安装包分发**：直接通过后端分发 `DeskCare_Setup.exe`，支持断点续传。

### 2.3 用户行为统计 (Analytics)
*   **启动活跃度 (DAU)**：通过唯一的机器码 (Machine ID) 统计每日活跃用户，不依赖 Cookie，更精准。
*   **安装来源追踪**：记录用户是从哪个推广链接或搜索引擎进入官网并下载的。

### 2.4 云端配置备份
*   **配置上传**：用户可将本地 DeskCare 配置一键上传至云端数据库。
*   **配置恢复**：在任何新设备上输入账号/密钥即可恢复之前的习惯设置。

## 3. 技术架构方案

### 3.1 技术栈
*   **Web 框架**: FastAPI (高性能异步框架)
*   **服务器**: Uvicorn (ASGI 服务器)
*   **数据库**: SQLite (轻量级，无需额外配置，适合中小型应用) + SQLAlchemy (ORM)
*   **IP 地理库**: GeoIP2 (MaxMind GeoLite2 数据库)
*   **前端技术**: Tailwind CSS (原子化 CSS) + ECharts 5 (数据可视化)
*   **部署工具**: Paramiko (Python SSH 库，用于自动化部署)

### 3.2 目录结构
```
backend_python/
├── app/
│   ├── core/           # 核心组件 (GeoIP 数据库)
│   ├── routers/        # API 路由 (analytics, dashboard, downloads, etc.)
│   ├── crud.py         # 数据库 CRUD 操作
│   ├── database.py     # 数据库连接配置
│   ├── main.py         # FastAPI 入口
│   ├── models.py       # SQLAlchemy 数据模型
│   └── schemas.py      # Pydantic 数据验证模型
├── files/              # 存放安装包 (DeskCare_Setup.exe) 和版本信息 (version_info.json)
├── static/             # 存放官网静态资源 (index.html, css, js)
├── deploy_remote.py    # 自动化部署脚本
├── requirements.txt    # Python 依赖列表
└── run.py              # 本地开发启动脚本
```

### 3.3 数据库设计
系统主要包含以下数据表：
*   `website_visits`: 记录所有 HTTP 请求日志 (IP, UA, Referrer, Geo, Device Type)。
*   `download_logs`: 记录软件下载行为 (Download Key 使用情况)。
*   `daily_usage`: 记录客户端启动活跃日志 (Machine ID, Version)。
*   `user_backups`: 存储用户的云端配置 JSON 数据。

## 4. 自动化部署指南

本项目包含一个全自动化的部署脚本 `deploy_remote.py`，能够一键将本地代码、静态资源和安装包同步到远程 Linux 服务器。

### 4.1 部署前准备
1.  **服务器准备**：一台安装了 Ubuntu/Debian 的 Linux 服务器。
2.  **配置修改**：打开 `deploy_remote.py`，修改以下配置：
    ```python
    HOST = "47.101.52.0"  # 服务器 IP
    USER = "root"         # SSH 用户名
    PASS = "YourPassword" # SSH 密码
    ```
3.  **本地依赖**：确保本地已安装 `paramiko` 库 (`pip install paramiko`)。

### 4.2 自动化部署流程
运行脚本：
```bash
python deploy_remote.py
```

脚本将自动执行以下步骤：
1.  **环境清理**：停止旧服务，清理 `/opt/deskcare` 目录。
2.  **文件同步**：
    *   **后端代码**：将 `app/` 目录上传到服务器。
    *   **官网部署**：将 `static/` 目录下的 HTML/CSS/JS 文件上传到 `/opt/deskcare/static/`。
    *   **安装包发布**：将 `files/DeskCare_Setup.exe` 上传到 `/opt/deskcare/files/`。
3.  **依赖安装**：在服务器上创建 Python 虚拟环境 (venv)，并安装 `requirements.txt` 中的所有依赖。
4.  **服务注册**：自动创建并配置 `systemd` 服务 (`deskcare.service`)，实现开机自启和进程守护。
5.  **启动验证**：启动服务并检查 API 健康状态。

### 4.3 静态资源与安装包更新
*   **更新官网**：只需将最新的 `index.html` 及相关资源放入本地 `backend_python/static/` 目录，重新运行部署脚本即可。
*   **发布新版本**：将新的安装包重命名为 `DeskCare_Setup.exe` 放入 `backend_python/files/`，修改 `version_info.json`，然后重新运行部署脚本。

## 5. 本地开发与运行

### 5.1 环境要求
*   Python 3.8+
*   pip

### 5.2 启动步骤
1.  安装依赖：
    ```bash
    pip install -r requirements.txt
    ```
2.  启动服务：
    ```bash
    python run.py
    ```
    服务将运行在 `http://localhost:8000`。

### 5.3 访问接口文档
启动后，访问以下地址查看自动生成的 API 文档：
*   Swagger UI: `http://localhost:8000/docs`
*   ReDoc: `http://localhost:8000/redoc`
