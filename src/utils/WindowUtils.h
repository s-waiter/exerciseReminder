#pragma once
#include <QObject>
#include <QWindow>

// ========================================================================
// WindowUtils 类：窗口工具类
// ========================================================================
// 作用：提供 QML 无法直接完成的底层窗口操作。
// 主要是为了解决 QML 中设置窗口置顶 (WindowStaysOnTopHint) 时，
// 在某些操作系统（尤其是 Windows）上可能导致的窗口闪烁或重绘问题。
class WindowUtils : public QObject {
    Q_OBJECT
public:
    explicit WindowUtils(QObject *parent = nullptr) : QObject(parent) {}

    // ========================================================================
    // Q_INVOKABLE 宏
    // ========================================================================
    // 将此成员函数暴露给 Qt 元对象系统，使其可以在 QML 中直接调用。
    // 即使该函数不是槽 (Slot)，也可以被调用。
    // 参数 window: QML 中的 Window 对象在 C++ 中对应为 QWindow 或 QQuickWindow。
    // 参数 top: true 为置顶，false 为取消置顶。
    Q_INVOKABLE void setTopMost(QObject *window, bool top);
};
