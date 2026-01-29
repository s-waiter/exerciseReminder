#include "WindowUtils.h"
#include <QDebug>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

void WindowUtils::setTopMost(QObject *window, bool top) {
    if (!window) return;
    
    QWindow *qWin = qobject_cast<QWindow*>(window);
    if (!qWin) {
        qDebug() << "WindowUtils: Passed object is not a QWindow";
        return;
    }

#ifdef Q_OS_WIN
    HWND hwnd = (HWND)qWin->winId();
    if (hwnd) {
        // SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE 确保只改变 Z 序，不改变位置大小和激活状态
        SetWindowPos(hwnd, top ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, 
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }
#else
    // 非 Windows 平台回退方案
    Qt::WindowFlags flags = qWin->flags();
    if (top) {
        flags |= Qt::WindowStaysOnTopHint;
    } else {
        flags &= ~Qt::WindowStaysOnTopHint;
    }
    qWin->setFlags(flags);
    // Qt setFlags 可能导致窗口隐藏，需要重新显示
    if (qWin->isVisible()) {
        qWin->show();
    }
#endif
}
