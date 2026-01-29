#pragma once
#include <QObject>
#include <QWindow>

class WindowUtils : public QObject {
    Q_OBJECT
public:
    explicit WindowUtils(QObject *parent = nullptr) : QObject(parent) {}

    // 设置窗口置顶状态（Windows 下使用 WinAPI 避免重绘闪烁）
    Q_INVOKABLE void setTopMost(QObject *window, bool top);
};
