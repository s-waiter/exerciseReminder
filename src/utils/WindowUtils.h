#pragma once
#include <QObject>
#include <QWindow>
#include <QVariantMap>
#include <QSet>

// ========================================================================
// WindowUtils 类：窗口工具类
// ========================================================================
// 作用：提供 QML 无法直接完成的底层窗口操作。
// 主要是为了解决 QML 中设置窗口置顶 (WindowStaysOnTopHint) 时，
// 在某些操作系统（尤其是 Windows）上可能导致的窗口闪烁或重绘问题。
// 同时负责监听系统级事件（如锁屏）。
class WindowUtils : public QObject {
    Q_OBJECT
public:
    explicit WindowUtils(QObject *parent = nullptr);
    ~WindowUtils();

    // ========================================================================
    // Q_INVOKABLE 宏
    // ========================================================================
    // 将此成员函数暴露给 Qt 元对象系统，使其可以在 QML 中直接调用。
    // 即使该函数不是槽 (Slot)，也可以被调用。
    // 参数 window: QML 中的 Window 对象在 C++ 中对应为 QWindow 或 QQuickWindow。
    // 参数 top: true 为置顶，false 为取消置顶。
    Q_INVOKABLE void setTopMost(QObject *window, bool top);

    // 获取主屏幕的可用几何区域 (x, y, width, height)
    // 返回值: QVariantMap { "x": int, "y": int, "width": int, "height": int }
    Q_INVOKABLE QVariantMap getPrimaryScreenAvailableGeometry();

    // 获取当前鼠标所在屏幕的可用几何区域
    // 用于手动启动时，让窗口出现在用户操作的那个屏幕上
    Q_INVOKABLE QVariantMap getScreenGeometryAtCursor();

    // 设置是否阻止系统休眠
    // prevent: true = 阻止休眠
    // prevent: false = 恢复正常
    // reason: (可选) 阻止休眠的原因标识符，用于支持多个组件同时请求阻止休眠。
    //         如果不提供 reason，则使用默认的全局开关 (兼容旧代码)。
    Q_INVOKABLE void setPreventSleep(bool prevent, const QString &reason = "");

signals:
    // 当系统会话状态改变时触发（true=锁屏, false=解锁）
    void sessionStateChanged(bool locked);

private:
    void updateSleepState();

    // 内部类，用于接收系统消息的隐藏窗口
    class SysMsgWindow;
    SysMsgWindow *m_sysMsgWindow;
    
    // 存储阻止休眠的原因集合
    QSet<QString> m_preventSleepReasons;
};
