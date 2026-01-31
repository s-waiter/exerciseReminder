
## 部署优化与问题修复 (P6 - 2026-01-31)

### 1. Git 管理优化
- **用户指令**：希望将网站开发内容加入 Git 管理，询问是否需要更新 `.gitignore`。
- **动作**：
    - 更新 `.gitignore`，添加 `!website_project/official_site/public/downloads/*.zip` 规则，确保下载资源被跟踪，同时排除其他不必要文件。
    - 修复了 Git 无法跟踪 zip 文件的问题。

### 2. 软件包格式调整 (Exe -> Zip)
- **用户指令**：指出仅下载 exe 无法运行（缺少 dll），要求改为下载包含完整依赖的 zip 压缩包。
- **动作**：
    - 在 `one_click_package.bat` 中集成压缩逻辑。
    - 修改官网 `Navbar.jsx` 和 `Hero.jsx`，将下载链接从 `.exe` 改为 `.zip`。
    - 重新生成 `ExerciseReminder_v1.0.zip` 并放置到 `public/downloads/` 目录。
    - 更新网站前端文案，明确提示下载的是 zip 完整包。

### 3. 自动化流程增强
- **用户指令**：请求在 `one_click_package.bat` 打包完成后，自动更新网站上的 zip 包并部署。
- **动作**：
    - 编写 Python 脚本 `package_zip.py` 替代不稳定的 PowerShell `Compress-Archive`，解决大文件压缩损坏问题。
    - 升级 `one_click_package.bat`，新增“自动部署到网站”选项。
    - 用户只需运行一个批处理脚本，即可完成：编译 C++ -> 打包依赖 -> 压缩 Zip -> 替换网站资源 -> 自动部署上线。

### 4. SmartScreen 警告处理
- **用户指令**：反馈从网站下载的 exe 运行时会出现 Windows SmartScreen 警告。
- **动作**：
    - 解释原因：软件未购买数字签名证书，属于正常现象。
    - 解决方案：
        1. **用户教育**：在官网下载区添加醒目的黄色提示框，指导用户点击“更多信息 -> 仍要运行”。
        2. **UI 优化**：使用 `lucide-react` 图标增强提示可读性。
    - 重新部署网站，实装上述变更。

### 5. 部署脚本修复
- **问题**：部署过程中 `downloads` 目录未正确同步到 Nginx 目录。
- **动作**：
    - 修改 `website_project/deploy/setup_remote.sh`，增加对 `downloads` 目录的移动操作，确保 zip 文件能被用户访问。

- **当前状态**：
    - 官网版本：v1.0 (Zip完整版)
    - 部署状态：已更新，包含 SmartScreen 提示。
    - 自动化：已实现一键打包部署。
