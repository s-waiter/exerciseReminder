#include "TrayIcon.h"
#include <QApplication>
#include <QAction>
#include <QStyle>

TrayIcon::TrayIcon(QObject *parent) : QObject(parent)
{
    // 初始化系统托盘对象
    m_trayIcon = new QSystemTrayIcon(this);
    
    // 设置图标：使用自定义 SVG 图标
    m_trayIcon->setIcon(QIcon(":/assets/images/tray_icon.svg"));
    
    // 创建右键菜单
    m_menu = new QMenu();
    
    // 美化右键菜单 (深色极简风 - 统一主界面风格)
    m_menu->setStyleSheet(
        "QMenu {"
        "   background-color: #243B55;"  // 统一主界面深蓝背景
        "   border: 1px solid #00d2ff;"  // 统一主界面科技蓝边框
        "   border-radius: 8px;"
        "   padding: 5px;"
        "}"
        "QMenu::item {"
        "   background-color: transparent;"
        "   color: #ffffff;"             // 纯白文字
        "   padding: 8px 20px;"
        "   border-radius: 4px;"
        "   font-family: 'Microsoft YaHei UI', 'Segoe UI';"
        "   font-size: 10pt;"
        "}"
        "QMenu::item:selected {"
        "   background-color: #00d2ff;"  // 选中高亮色保持一致
        "   color: #000000;"
        "   font-weight: bold;"
        "}"
        "QMenu::separator {"
        "   height: 1px;"
        "   background: rgba(255, 255, 255, 0.2);" // 半透明分割线
        "   margin: 4px 10px;"
        "}"
    );
    
    QAction *showAction = m_menu->addAction("⚙️  显示设置");
    connect(showAction, &QAction::triggered, this, &TrayIcon::showSettingsRequested);
    
    m_menu->addSeparator();
    
    QAction *quitAction = m_menu->addAction("🚪  退出程序");
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
