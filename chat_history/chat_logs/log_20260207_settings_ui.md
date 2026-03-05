# 聊天记录 - 2026-02-07 设置界面与提醒UI优化

## 1. 用户需求
1. **提醒类型卡片分类色**：在 ScheduleListWindow.qml 中，提醒类型的筛选卡片（Tabs）需要使用对应的分类颜色（工作-蓝，休息-绿，重要-红，健康-紫）。选中时显示20%透明度背景和对应颜色的边框/文字，未选中时透明。保持悬浮位移动画。
2. **主设置界面调整**：
   - 移除主界面（Main.qml）上的日历图标（原本的提醒界面入口）。
   - 将原本的“间隔时长”设置按钮改为“提醒事项”入口，点击打开 ScheduleListWindow。
   - 保持 UI 风格一致。
3. **偏好设置迁移**：
   - 将“间隔时长”的设置功能（数值显示、+/-按钮、滚轮调节、单击重置）移至 SettingsOverlay.qml 中。
   - 保持与其他设置项（如开机自启）一致的视觉风格。

## 2. 修改文件
### a. `assets/qml/ScheduleListWindow.qml`
- **修复 Bug**：`getCardColor(type)` 函数增加 `type === -1` 的处理，返回白色 (`#FFFFFF`)，解决了“全部”标签颜色错误的问题。
- **样式调整**：更新 Filter Delegate 的 `color` 和 `border.color` 绑定逻辑，实现选中态的高亮效果。

### b. `assets/qml/Main.qml`
- **隐藏旧入口**：将 `scheduleBtn`（日历图标）的 `visible` 设为 `false`。
- **功能转换**：将 `intervalCard`（原间隔设置）改造为提醒界面入口。
  - 移除原有的鼠标滚轮和点击设置逻辑。
  - 添加 `onClicked: openScheduleWindow()`。
  - 更新图标为 "📅" 和文字为 "提醒事项"。
- **懒加载优化**：确认 `scheduleLoader` 使用懒加载模式，并在加载完成时正确处理窗口隐藏/显示逻辑。

### c. `assets/qml/SettingsOverlay.qml`
- **布局调整**：高度从 `200` 增加到 `260`，以容纳新选项。
- **新增功能**：在 `Column` 中添加“间隔时长”设置项。
  - 复用 `timerEngine.workDurationMinutes` 和 `appConfig.workDuration`。
  - 实现 `+` / `-` 按钮点击事件。
  - 实现中间数值区域的鼠标滚轮调节和单击重置（重置为 45分钟）。
  - 保持与原 UI 一致的半透明圆角矩形风格。

## 3. 验证检查
- **编译/运行**：检查了 `timerEngine` 和 `appConfig` 在 `SettingsOverlay` 中的可用性（确认为全局上下文属性）。
- **逻辑正确性**：
  - 筛选卡片颜色逻辑：`index - 1` 正确映射到 `-1` (全部) 到 `3` (健康)。
  - 窗口交互：从 Main 点击新入口 -> 打开 ScheduleListWindow -> 关闭时返回 Main，逻辑闭环。
  - 设置同步：SettingsOverlay 修改时长会立即同步到 `timerEngine` 和 `appConfig`。
- **UI 适配**：SettingsOverlay 高度增加后，内容垂直居中，不会溢出。

## 4. 时间记录
- **开始时间**: 2026-02-07 10:35:00 (预估)
- **结束时间**: 2026-02-07 10:42:00
- **总耗时**: 7 分钟
