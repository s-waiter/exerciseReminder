# DeskCare 技术文档 (Technical Specification) v1.1

## 1. 项目简介 (Introduction)

本项目是“DeskCare”的官方宣传网站。网站旨在通过现代化、高视觉冲击力的设计，展示软件的核心功能、设计理念，并提供软件下载服务。

项目采用现代前端技术栈构建，注重性能优化和用户体验，确保在各种设备上都能流畅访问。

## 2. 技术栈 (Technology Stack)

### 2.1 前端核心 (Frontend Core)
-   **Framework**: [React v19](https://react.dev/) - 构建用户界面的核心库。
-   **Build Tool**: [Vite v7](https://vitejs.dev/) - 下一代前端构建工具，提供极速的开发服务器和打包体验。
-   **Language**: JavaScript (ES Modules)

### 2.2 样式与动画 (Styling & Animation)
-   **Styling**: [Tailwind CSS v4](https://tailwindcss.com/) - 实用优先的 CSS 框架，通过 `@tailwindcss/vite` 插件集成。
-   **Animation**: [Framer Motion](https://www.framer.com/motion/) - 强大的 React 动画库，用于实现滚动视差、元素渐入、Bento Grid 交互等复杂动效。
-   **Icons**: [Lucide React](https://lucide.dev/) - 轻量级、风格统一的 SVG 图标库。

### 2.3 部署与运维 (Deployment & DevOps)
-   **Server**: Nginx - 高性能 HTTP 和反向代理服务器。
-   **OS**: Ubuntu 24.04 LTS (阿里云轻量应用服务器)。
-   **Automation**: Python (`paramiko`) + Shell Scripts - 自定义自动化部署脚本。

## 3. 架构设计 (Architecture)

### 3.1 前端架构
采用 **单页应用 (SPA)** 架构，通过组件化开发实现高复用性。

*   **组件结构**:
    *   `App.jsx`: 根组件，负责整体布局结构。
    *   `Navbar`: 响应式导航栏，支持桌面端和移动端（汉堡菜单），具备磨砂玻璃 (Glassmorphism) 效果。
    *   `Hero`: 首屏展示，包含粒子背景、核心 Slogan、软件 UI 模拟 (CSS 纯代码实现) 和下载入口。
    *   `Features`: 特性介绍，采用 **Bento Grid** 布局，结合 CSS UI 模拟展示核心功能（智能定时、个性化设置、极简模式、强制休息）。
    *   `FAQ`: 常见问题解答，解决用户关于 SmartScreen 警告、免费政策等疑虑。
    *   `Footer`: 底部信息，包含版权和社交链接。
    *   `ParticleBackground`: 基于 Canvas 的自定义粒子系统，实现高性能的动态背景。

### 3.2 部署架构
由于服务器资源有限 (2C2G)，项目采用 **预构建 (Pre-built)** 策略：
1.  **本地构建**: 在开发机上运行 `npm run build` 生成静态文件 (`dist/`)。
2.  **文件传输**: 使用 Python `paramiko` 库通过 SFTP 将构建产物和部署脚本上传至服务器 `/tmp` 目录。
3.  **远程执行**: 通过 SSH 执行服务器上的 Shell 脚本，将文件移动到 Nginx 托管目录，并重载服务。

## 4. 目录结构 (Directory Structure)

```
website_project/
├── deploy/                     # 部署相关脚本
│   ├── exercise_site.conf      # Nginx 配置文件
│   └── setup_remote.sh         # 服务器端执行的安装/更新脚本
├── official_site/              # 前端源码 (React + Vite)
│   ├── public/                 # 静态资源 (favicon, downloads/)
│   │   └── downloads/          # 存放软件安装包 (zip)
│   ├── src/                    # 源代码
│   │   ├── assets/             # 图片与图标资源
│   │   ├── components/         # React 组件 (Hero, Features, etc.)
│   │   ├── App.jsx             # 主应用组件
│   │   ├── main.jsx            # 入口文件
│   │   └── index.css           # 全局样式 (Tailwind 指令)
│   ├── dist/                   # 构建产出目录 (由 npm run build 生成)
│   ├── vite.config.js          # Vite 配置
│   └── package.json            # 项目依赖定义
├── deploy.py                   # 自动化部署入口脚本 (Python)
├── requirements.md             # 需求文档
└── technical_spec.md           # 技术文档 (本文档)
```

## 5. 开发指南 (Development Guide)

### 5.1 环境要求
-   Node.js >= 18.0.0
-   Python 3.x (用于部署脚本)
-   Git

### 5.2 安装依赖
```bash
cd website_project/official_site
npm install
```

### 5.3 启动开发服务器
```bash
npm run dev
```
访问 `http://localhost:5173` 进行预览。

### 5.4 构建生产版本
```bash
npm run build
```
构建产物将输出到 `official_site/dist` 目录。

## 6. 部署流程 (Deployment Process)

### 6.1 准备工作
1.  确保本地已安装 Python `paramiko` 库: `pip install paramiko`
2.  确保 `deploy.py` 中的服务器配置 (IP, User, Password) 正确。
3.  确保软件安装包已放入 `official_site/public/downloads/`。

### 6.2 执行部署
在项目根目录 (`website_project`) 下运行：
```bash
python deploy.py
```

### 6.3 部署脚本逻辑 (`deploy.py`)
1.  **连接**: 建立 SSH 连接。
2.  **上传**: 将 `official_site/dist` (包含构建后的静态文件和 zip 包) 上传至服务器 `/tmp`。
3.  **脚本上传**: 上传 `deploy/setup_remote.sh` 和 `deploy/exercise_site.conf`。
4.  **执行**: 运行远程脚本 `setup_remote.sh`。
    *   安装 Nginx (如果未安装)。
    *   配置防火墙 (UFW)。
    *   创建/清理 `/var/www/exercise-reminder` 目录。
    *   将 `/tmp` 中的文件移动到 Web 根目录。
    *   配置 Nginx 站点并重启服务。

## 7. 关键功能实现细节 (Implementation Details)

### 7.1 粒子背景 (ParticleBackground.jsx)
使用 HTML5 Canvas API 实现。
-   **优化**: 使用 `requestAnimationFrame` 进行渲染循环。
-   **交互**: 粒子会对鼠标移动产生微弱的视差响应，增加沉浸感。

### 7.2 UI 模拟 (CSS Mockups)
在 `Features.jsx` 和 `Hero.jsx` 中，软件界面截图并非使用图片，而是通过 **Tailwind CSS** 类名手写 HTML/CSS 模拟。
-   **优势**: 
    -   体积极小 (无图片加载)。
    -   无限缩放不失真。
    -   方便后期修改文案和配色，无需重新切图。
    -   支持 CSS 动画 (如呼吸灯、进度条动画)。

### 7.3 响应式设计
-   **Mobile First**: 默认样式适配移动端。
-   **Breakpoints**: 使用 `md:`, `lg:` 前缀适配平板和桌面端。
-   **导航栏**: 移动端自动折叠为汉堡菜单，桌面端展开链接。

## 8. 维护与注意事项 (Maintenance)

-   **软件更新**: 若需发布新版本软件，请将新的 zip 包放入 `public/downloads/`，更新 `Hero.jsx` 中的下载链接，然后重新运行构建和部署。
-   **HTTPS**: 当前使用 HTTP (IP访问)。建议后续申请域名并配置 SSL 证书 (Let's Encrypt) 以消除浏览器“不安全”警告。
-   **SmartScreen**: 网站已添加针对 Windows SmartScreen 的提示，告知用户如何绕过警告 (更多信息 -> 仍要运行)。
