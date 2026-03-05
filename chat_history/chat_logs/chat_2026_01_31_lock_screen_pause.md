# 实现锁屏自动暂停倒计时功能 (2026-01-31)

## 需求描述
用户提出，当操作系统锁屏时（例如用户离开去吃饭），倒计时应当暂停；当用户解除锁屏时，倒计时应当自动继续。这可以防止用户在离开期间倒计时仍在运行，导致统计数据不准确。

## 技术方案
1.  **系统事件监听**：
    *   使用 Windows API `WTSRegisterSessionNotification` 注册当前窗口以接收会话变更通知。
    *   通过继承 `QAbstractNativeEventFilter` 实现 `WindowUtils` 类，拦截并处理 `WM_WTSSESSION_CHANGE` 消息。
    *   识别 `WTS_SESSION_LOCK` (锁屏) 和 `WTS_SESSION_UNLOCK` (解锁) 事件。

2.  **倒计时引擎修改**：
    *   在 `TimerEngine` 中添加 `handleSystemLock(bool locked)` 槽函数。
    *   引入 `m_pausedBySystem` 标志位，用于区分是用户手动暂停还是系统自动暂停。
    *   **锁屏时**：如果定时器正在运行，暂停定时器，设置 `m_pausedBySystem = true`。
    *   **解锁时**：如果 `m_pausedBySystem` 为 true，恢复定时器，重置标志位。

3.  **集成**：
    *   在 `main.cpp` 中将 `windowUtils` 安装为应用程序的原生事件过滤器。
    *   在 QML 主窗口加载完成后，调用 `registerForSessionNotifications`。
    *   连接 `WindowUtils` 的 `sessionStateChanged` 信号到 `TimerEngine` 的 `handleSystemLock` 槽。

## 修改文件
- `DeskCare.pro`: 添加 `wtsapi32` 库链接。
- `src/utils/WindowUtils.h/cpp`: 实现原生事件过滤和信号发射。
- `src/core/TimerEngine.h/cpp`: 实现暂停/恢复逻辑。
- `src/main.cpp`: 完成组件装配和信号连接。

## 验证
通过代码审查，逻辑覆盖了正常工作流程和边缘情况（如手动暂停后锁屏，解锁后不应自动开始）。
