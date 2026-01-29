#include "WindowUtils.h"
#include <QDebug>

// #ifdef Q_OS_WIN 是 Qt 的宏，仅在 Windows 平台编译此段代码
#ifdef Q_OS_WIN
#include <windows.h> // 引入 Windows API 头文件
#endif

// ========================================================================
// 设置窗口置顶 (跨平台实现)
// ========================================================================
// 核心逻辑：
// 1. 尝试将传入的 QObject 转换为 QWindow 指针。
// 2. Windows 平台：使用原生 WinAPI SetWindowPos，避免窗口闪烁。
// 3. 其他平台：使用 Qt 标准 API setFlags。
void WindowUtils::setTopMost(QObject *window, bool top) {
    // 安全检查：防止空指针崩溃
    if (!window) return;
    
    // qobject_cast 是 Qt 的动态类型转换机制 (类似 C++ dynamic_cast)。
    // 它依赖于元对象系统，如果转换失败（对象不是 QWindow 类型），返回 nullptr。
    QWindow *qWin = qobject_cast<QWindow*>(window);
    if (!qWin) {
        qDebug() << "WindowUtils: Passed object is not a QWindow";
        return;
    }

#ifdef Q_OS_WIN
    // ====================================================================
    // Windows 平台原生实现
    // ====================================================================
    // 获取窗口句柄 (HWND)。winId() 返回的是平台相关的窗口标识符。
    HWND hwnd = (HWND)qWin->winId();
    if (hwnd) {
        // SetWindowPos 是 Windows API 函数，用于改变窗口的大小、位置和 Z 序。
        // HWND_TOPMOST: 将窗口置于所有非置顶窗口之上。
        // HWND_NOTOPMOST: 取消置顶。
        // SWP_NOMOVE: 忽略 x, y 参数（不移动位置）。
        // SWP_NOSIZE: 忽略 cx, cy 参数（不改变大小）。
        // SWP_NOACTIVATE: 不激活窗口（不抢占焦点）。
        // 这种方式比 Qt 的 setFlags 更高效且平滑，不会导致窗口隐藏再显示。
        SetWindowPos(hwnd, top ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, 
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }
#else
    // ====================================================================
    // 其他平台 (macOS/Linux) 通用实现
    // ====================================================================
    // 获取当前窗口的标志位
    Qt::WindowFlags flags = qWin->flags();
    if (top) {
        // 使用位运算 OR 添加置顶标志
        flags |= Qt::WindowStaysOnTopHint;
    } else {
        // 使用位运算 AND NOT 移除置顶标志
        flags &= ~Qt::WindowStaysOnTopHint;
    }
    // 设置新的标志位
    // 注意：在某些平台上，调用 setFlags 可能会导致窗口重新创建或隐藏。
    qWin->setFlags(flags);
    
    // 如果窗口原本是显示的，需要重新调用 show() 确保它可见
    if (qWin->isVisible()) {
        qWin->show();
    }
#endif
}
