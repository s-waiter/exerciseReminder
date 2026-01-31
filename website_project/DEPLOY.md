# 部署指南 (Deployment Guide)

本指南用于将《久坐提醒》官网部署到阿里云轻量应用服务器。

## 1. 准备工作

本地已完成项目构建，生成了 `official_site/dist` 目录。
部署相关文件已生成在 `website_project` 目录：
- `deploy.py`: Python 自动化部署脚本 (依赖 `paramiko`)
- `deploy/setup_remote.sh`: 服务器初始化脚本
- `deploy/exercise_site.conf`: Nginx 配置文件

## 2. 自动化部署 (Automated Deployment)

我们已编写 Python 脚本实现一键部署（自动上传文件、配置环境、重启服务）。

### 前置要求
确保本地安装了 `paramiko` 库：
```bash
pip install paramiko
```
*(注：本项目已自动配置，无需手动安装)*

### 执行部署
在 `website_project` 目录下运行：
```powershell
python deploy.py
```

脚本将自动完成以下操作：
1. 连接服务器 (47.101.52.0)。
2. 上传 `dist` 目录和配置文件。
3. 远程执行 `setup_remote.sh` 脚本进行环境配置。

## 3. 手动部署 (Manual Fallback)

如果自动化脚本失败，可使用以下手动步骤：

### 第一步：上传文件
```powershell
scp -r official_site/dist/* deploy/setup_remote.sh deploy/exercise_site.conf root@47.101.52.0:/tmp/
```
> 密码：`Pass1234`

### 第二步：执行安装
```powershell
ssh root@47.101.52.0 "bash /tmp/setup_remote.sh"
```
> 密码：`Pass1234`

## 4. 验证 (Verification)

访问：http://47.101.52.0

## 5. 维护 (Maintenance)

更新代码后：
1. `npm run build`
2. 运行 `python deploy.py`
