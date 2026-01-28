#pragma once
#include <QObject>
#include <QSystemTrayIcon>
#include <QMenu>

// 托盘图标管理器：负责系统托盘的显示、菜单交互
class TrayIcon : public QObject
{
    Q_OBJECT
public:
    explicit TrayIcon(QObject *parent = nullptr);
    
    // 显示气泡消息
    void showMessage(const QString &title, const QString &msg);

signals:
    // 请求显示主设置界面
    void showSettingsRequested();
    // 请求退出程序
    void quitRequested();

public slots:
    // 更新鼠标悬停时的提示文本
    void updateToolTip(const QString &text);

private slots:
    // 处理托盘激活事件（单击、双击）
    void onActivated(QSystemTrayIcon::ActivationReason reason);

private:
    QSystemTrayIcon *m_trayIcon;
    QMenu *m_menu;
};
