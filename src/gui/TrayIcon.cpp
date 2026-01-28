#include "TrayIcon.h"
#include <QApplication>
#include <QAction>
#include <QStyle>

TrayIcon::TrayIcon(QObject *parent) : QObject(parent)
{
    // 初始化系统托盘对象
    m_trayIcon = new QSystemTrayIcon(this);
    
    // 设置图标：暂时使用系统自带的计算机图标作为占位符
    // 实际项目中应加载自定义的 .ico 或 .png
    m_trayIcon->setIcon(QApplication::style()->standardIcon(QStyle::SP_ComputerIcon));
    
    // 创建右键菜单
    m_menu = new QMenu();
    
    QAction *showAction = m_menu->addAction("显示设置");
    connect(showAction, &QAction::triggered, this, &TrayIcon::showSettingsRequested);
    
    m_menu->addSeparator();
    
    QAction *quitAction = m_menu->addAction("退出");
    connect(quitAction, &QAction::triggered, this, &TrayIcon::quitRequested);

    m_trayIcon->setContextMenu(m_menu);
    
    // 连接激活信号（如点击托盘图标）
    connect(m_trayIcon, &QSystemTrayIcon::activated, this, &TrayIcon::onActivated);
    
    // 显示托盘图标
    m_trayIcon->show();
}

void TrayIcon::showMessage(const QString &title, const QString &msg) {
    m_trayIcon->showMessage(title, msg);
}

void TrayIcon::updateToolTip(const QString &text) {
    m_trayIcon->setToolTip(text);
}

void TrayIcon::onActivated(QSystemTrayIcon::ActivationReason reason) {
    // 单击或双击时触发显示主界面信号
    if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
        emit showSettingsRequested();
    }
}
