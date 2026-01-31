# 修复图表悬停暂停失效问题 (2026-01-31)

## 1. 问题复盘
- **现象**：用户反馈悬停暂停倒计时、卡片浮起效果未生效。
- **原因分析**：
  - `OverlayWindow` 中存在一个全局的 `MouseArea` (id: `mouseTracker`) 用于视差特效，其 Z 轴层级为 **1000**。
  - 原来的 `feedbackLayer`（包含图表和悬停检测）的 Z 轴层级为 **999**。
  - 由于 `mouseTracker` 位于更上层且开启了 `hoverEnabled: true`，它拦截了所有的鼠标悬停事件，导致下层的 `feedbackMouseArea` 无法接收到 `containsMouse` 信号。
- **结论**：层级遮挡导致悬停检测失效。

## 2. 修复方案
1.  **调整层级**：将 `feedbackLayer` 的 Z 轴层级从 **999** 提升至 **1001**，确保其覆盖在 `mouseTracker` 之上。
2.  **优化交互区域**：将 `feedbackMouseArea` 从覆盖全屏（`parent`）改为仅覆盖核心内容卡片 (`resultCard` / `cardBg`)。
    - **优点**：更精准的交互体验。用户只需将鼠标放在中间的数据卡片上即可暂停，移开（即使还在屏幕边缘）即可恢复倒计时。这也解决了“移出”界定的问题。

## 3. 修改文件
- `src/gui/OverlayWindow.qml` (实际路径: `assets/qml/OverlayWindow.qml`)

## 4. 验证预期
- 用户完成运动后，结算界面弹出。
- 鼠标移入中间卡片区域 -> 卡片微放大，倒计时进度条暂停，提示文字变更。
- 鼠标移出中间卡片区域 -> 卡片恢复，倒计时继续，结束后自动关闭。
