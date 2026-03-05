# 修复 QML 信号连接警告 (2026-01-31)

## 1. 问题描述
用户反馈运行时输出中存在红色警告信息：
```
qrc:/assets/qml/Main.qml:1394:5: QML Connections: Detected function "onShowSettingsRequested" in Connections element. This is probably intended to be a signal handler but no signal of the target matches the name.
```

## 2. 原因分析
- **QML 端**：`Main.qml` 中的 `Connections` 组件试图连接名为 `onShowSettingsRequested` 的信号处理函数。这对应于 C++ 对象应该有一个名为 `showSettingsRequested` 的信号。
- **C++ 端**：检查 `TrayIcon.h` 和 `TrayIcon.cpp` 发现，实际定义的信号名为 `showMainWindowRequested`。
- **结论**：信号名称不匹配导致连接失败，QML 引擎发出警告，且托盘图标点击唤起主界面的功能可能失效。

## 3. 修复方案
修改 `assets/qml/Main.qml`，将信号处理函数名称从 `onShowSettingsRequested` 更正为 `onShowMainWindowRequested`，以匹配 C++ `TrayIcon` 类中定义的信号。

```qml
// 修改前
function onShowSettingsRequested() { ... }

// 修改后
function onShowMainWindowRequested() { ... }
```

## 4. 修改文件
- `src/gui/Main.qml` (实际路径: `assets/qml/Main.qml`)

## 5. 验证结果
- 信号名称一致，警告将消失。
- 点击托盘图标应能正常唤起主窗口。
