#include "WindowUtils.h"
#include <QDebug>
#include <QGuiApplication>
#include <QScreen>
#include <QCursor>

// #ifdef Q_OS_WIN 是 Qt 的宏，仅在 Windows 平台编译此段代码
#ifdef Q_OS_WIN
#include <windows.h> // 引入 Windows API 头文件
#include <wtsapi32.h> // 引入 Windows Terminal Services API
#endif

// ========================================================================
// SysMsgWindow: 专用消息接收窗口
// ========================================================================
class WindowUtils::SysMsgWindow : public QWindow {
public:
    explicit SysMsgWindow(WindowUtils *parent) : QWindow(), m_parent(parent) {
        // 设置窗口标志：无边框、工具窗口（不显示在任务栏）
        setFlags(Qt::FramelessWindowHint | Qt::Tool);
        
        // 创建底层窗口句柄
        // 必须先 create() 才有 HWND
        create();
        
#ifdef Q_OS_WIN
        HWND hwnd = (HWND)winId();
        if (hwnd) {
            // 注册会话通知
            if (WTSRegisterSessionNotification(hwnd, NOTIFY_FOR_THIS_SESSION)) {
                qDebug() << "SysMsgWindow: Successfully registered for session notifications. HWND:" << hwnd;
            } else {
                qDebug() << "SysMsgWindow: Failed to register. Error:" << GetLastError();
            }
        }
#endif
    }

    ~SysMsgWindow() {
#ifdef Q_OS_WIN
        HWND hwnd = (HWND)winId();
        if (hwnd) {
            WTSUnRegisterSessionNotification(hwnd);
        }
#endif
    }

protected:
    // 重写 nativeEvent 处理原生消息
    bool nativeEvent(const QByteArray &eventType, void *message, long *result) override {
        Q_UNUSED(eventType);
        Q_UNUSED(result);
        
#ifdef Q_OS_WIN
        MSG *msg = static_cast<MSG *>(message);
        if (msg->message == WM_WTSSESSION_CHANGE) {
            qDebug() << "SysMsgWindow: Received WM_WTSSESSION_CHANGE. wParam:" << msg->wParam;
            switch (msg->wParam) {
                case WTS_SESSION_LOCK:
                    qDebug() << "SysMsgWindow: Session Locked";
                    emit m_parent->sessionStateChanged(true);
                    break;
                case WTS_SESSION_UNLOCK:
                    qDebug() << "SysMsgWindow: Session Unlocked";
                    emit m_parent->sessionStateChanged(false);
                    break;
                default:
                    break;
            }
        }
#endif
        return false;
    }

private:
    WindowUtils *m_parent;
};

// ========================================================================
// WindowUtils 实现
// ========================================================================

WindowUtils::WindowUtils(QObject *parent) : QObject(parent), m_sysMsgWindow(nullptr) {
    // 创建隐藏的消息接收窗口
    // 注意：必须在 GUI 线程中创建
    m_sysMsgWindow = new SysMsgWindow(this);
}

WindowUtils::~WindowUtils() {
    if (m_sysMsgWindow) {
        delete m_sysMsgWindow;
        m_sysMsgWindow = nullptr;
    }
}

// 设置窗口置顶 (跨平台实现)
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

QVariantMap WindowUtils::getPrimaryScreenAvailableGeometry() {
    QVariantMap result;
    QScreen *primary = QGuiApplication::primaryScreen();
    if (primary) {
        QRect geo = primary->availableGeometry();
        result["x"] = geo.x();
        result["y"] = geo.y();
        result["width"] = geo.width();
        result["height"] = geo.height();
    } else {
        // Fallback defaults
        result["x"] = 0;
        result["y"] = 0;
        result["width"] = 1920;
        result["height"] = 1080;
    }
    return result;
}

QVariantMap WindowUtils::getScreenGeometryAtCursor() {
    QVariantMap result;
    QScreen *targetScreen = QGuiApplication::screenAt(QCursor::pos());
    
    // 如果找不到（极少情况），回退到主屏幕
    if (!targetScreen) {
        targetScreen = QGuiApplication::primaryScreen();
    }

    if (targetScreen) {
        QRect geo = targetScreen->availableGeometry();
        result["x"] = geo.x();
        result["y"] = geo.y();
        result["width"] = geo.width();
        result["height"] = geo.height();
    } else {
        // 彻底的 Fallback
        result["x"] = 0;
        result["y"] = 0;
        result["width"] = 1920;
        result["height"] = 1080;
    }
    return result;
}
