# 编译警告修复记录 - 2026-01-31 (补充)

## 用户反馈 (第二轮)
用户指出 `src/updater/main.cpp` 中存在 `QProcess` 相关的弃用警告：
1. `'execute' is deprecated` (main.cpp:51)
2. `'start' is deprecated` (main.cpp:66)

## 分析与修复

这是由于 Qt 5.15+ / Qt 6 建议避免使用单个字符串作为命令来启动进程（因为参数解析可能存在歧义），而是建议将程序名和参数列表分开传递。

### 1. `QProcess::execute` (updater/main.cpp)
- **问题代码**：`QProcess::execute("taskkill /F /IM " + m_appName);`
- **修复代码**：
  ```cpp
  QProcess::execute("taskkill", QStringList() << "/F" << "/IM" << m_appName);
  ```

### 2. `QProcess::start` (updater/main.cpp)
- **问题代码**：`process.start(cmd);` （其中 cmd 是包含 powershell 命令的完整字符串）
- **修复代码**：
  ```cpp
  QString psCommand = QString("Expand-Archive -Path '%1' -DestinationPath '%2' -Force")
                        .arg(m_zipPath).arg(m_installDir);
  process.start("powershell", QStringList() << "-command" << psCommand);
  ```
- 同时将 `.arg(a, b)` 改为链式调用 `.arg(a).arg(b)` 以符合新版 Qt API 规范。

## 结果
代码已更新，符合现代 Qt API 标准，消除了弃用警告。
