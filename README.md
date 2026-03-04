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
├── deploy_full.py      # 【核心】全自动化部署脚本
├── one_click_package.bat # (可选) 旧版自动打包脚本
├── version_info.json   # 全局版本控制文件
└── ...
```

## 3. 详细功能

### 3.1 官网前端 (Frontend)
*   基于 React 和 Vite 构建的现代化响应式网站。
*   展示软件功能、特性、下载入口。
*   通过 `npm run build` 生成静态文件，自动集成到后端。

### 3.2 后端服务 (Backend)
*   **API 服务**: 提供版本检测、下载鉴权、数据上报接口。
*   **管理后台**: `/admin/dashboard` 提供可视化的数据看板 (PV/UV, 下载量, 用户画像)。
*   **静态托管**: 自动托管前端构建生成的静态文件 (`index.html`, css, js)。

## 4. 自动化部署

本项目使用 `deploy_full.py` 脚本实现从前端构建到后端发布的全流程自动化。

**注意：脚本支持分模块独立部署，无需每次都全量更新。**

### 4.1 部署前准备
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

### 4.2 部署命令
在项目根目录运行 `python deploy_full.py [mode]`，其中 `[mode]` 支持以下参数：

*   `all`: **全量部署**（默认）。构建前端 + 部署后端 + 上传安装包。
*   `frontend`: **仅部署官网**。只构建 React 前端并更新服务器上的静态文件。
*   `backend`: **仅部署后端**。只更新 Python 代码并重启服务，不影响静态资源和安装包。
*   `app`: **仅发布安装包**。自动查找根目录下最新的 `DeskCare_vX.X.X.zip` 并上传到服务器。

**示例：**

```bash
# 场景1：修改了 Python 代码
python deploy_full.py backend

# 场景2：修改了官网文案
python deploy_full.py frontend

# 场景3：打包了新版软件，需要发布 (确保根目录有 DeskCare_v1.0.7.zip)
python deploy_full.py app
```

### 4.3 安装包发布说明
1.  使用 `one_click_package.bat` 或手动打包生成 `DeskCare_vX.X.X.zip`。
2.  将 ZIP 包放在项目根目录。
3.  运行 `python deploy_full.py app`。
4.  脚本会自动找到最新版本的 ZIP 包上传到 `/opt/deskcare/files/`，并同步 `version_info.json`。

## 5. 本地开发指南

### 5.1 启动后端
```bash
cd backend
pip install -r requirements.txt
python run.py
```
后端服务地址: `http://localhost:8000`

### 5.2 启动前端
```bash
cd frontend
npm install
npm run dev
```
前端开发地址: `http://localhost:5173`
