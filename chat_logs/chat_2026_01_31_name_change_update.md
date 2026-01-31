## 软件名称变更与网站更新 (2026-01-31)

### 1. 软件名称变更 (ExerciseReminder -> DeskCare)
- **用户指令**：软件名称已从 exercisereminder 全面修改为 DeskCare，要求更新并部署网站。
- **动作**：
    - 全局搜索并替换项目中的旧名称引用。
    - 更新 `website_project/technical_spec.md` 文档中的名称。
    - 更新 `website_project/deploy/setup_remote.sh` 部署脚本中的日志信息。
    - 更新 `website_project/official_site/src/components/Hero.jsx` 中的界面演示文字。
    - 重新构建前端项目 (`npm run build`)。
    - 执行自动化部署脚本 (`python deploy.py`)。

### 2. 部署状态
- **结果**：网站已成功更新并部署到服务器。
- **验证**：部署脚本执行成功，文件已上传。
