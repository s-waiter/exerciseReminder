#include "TrayIcon.h"
#if defined(_MSC_VER) && (_MSC_VER >= 1600)
# pragma execution_character_set("utf-8")
#endif
#include <QApplication>
#include <QStyle>
#include <QMessageBox>
#include <QProcess>
#include <QDebug>
#include <QAbstractButton>
#include <QPushButton>
#include <QFile>
#include "../core/TimerEngine.h"

TrayIcon::TrayIcon(TimerEngine *timerEngine, UpdateManager *updateManager, QObject *parent) 
    : QObject(parent), 
      m_timerEngine(timerEngine),
      m_updateManager(updateManager)
{
    // Initialize system tray
    m_trayIcon = new QSystemTrayIcon(this);
    m_trayIcon->setIcon(QIcon(":/assets/images/tray_icon.svg"));
    
    // Create menu
    createMenu();
    
    // Setup connections
    setupConnections();
    
    // Show tray
    m_trayIcon->show();

    // Auto check update on startup (silent)
    m_updateManager->checkForUpdates(true);
}

TrayIcon::~TrayIcon() {
    delete m_trayMenu;
}

void TrayIcon::createMenu() {
    m_trayMenu = new QMenu();
    
    // Style (Dark Theme)
    m_trayMenu->setStyleSheet(
        "QMenu {"
        "   background-color: #243B55;"
        "   border: 1px solid #00d2ff;"
        "   border-radius: 8px;"
        "   padding: 5px;"
        "}"
        "QMenu::item {"
        "   background-color: transparent;"
        "   color: #ffffff;"
        "   padding: 8px 20px;"
        "   border-radius: 4px;"
        "   font-family: 'Microsoft YaHei UI', 'Segoe UI';"
        "   font-size: 10pt;"
        "}"
        "QMenu::item:selected {"
        "   background-color: #00d2ff;"
        "   color: #000000;"
        "   font-weight: bold;"
        "}"
        "QMenu::separator {"
        "   height: 1px;"
        "   background: rgba(255, 255, 255, 0.2);"
        "   margin: 4px 10px;"
        "}"
    );

    // Actions
    m_startAction = m_trayMenu->addAction("▶ 开始专注");
    m_pauseAction = m_trayMenu->addAction("⏸ 暂停计时");
    m_skipAction = m_trayMenu->addAction("⏭ 跳过休息");
    m_resetAction = m_trayMenu->addAction("🔄 重置计时");
    
    m_trayMenu->addSeparator();
    
    m_checkUpdateAction = m_trayMenu->addAction("☁ 检查更新");

    m_trayMenu->addSeparator();
    
    m_quitAction = m_trayMenu->addAction("🚪 退出程序");

    m_trayIcon->setContextMenu(m_trayMenu);
    
    // Update dynamic state
    updateMenuState();
}

void TrayIcon::setupConnections() {
    // Tray interactions
    connect(m_trayIcon, &QSystemTrayIcon::activated, this, &TrayIcon::onActivated);
    
    // Timer interactions
    connect(m_startAction, &QAction::triggered, m_timerEngine, &TimerEngine::togglePause);
    connect(m_pauseAction, &QAction::triggered, m_timerEngine, &TimerEngine::stop);
    connect(m_skipAction, &QAction::triggered, m_timerEngine, &TimerEngine::startWork);
    connect(m_resetAction, &QAction::triggered, m_timerEngine, &TimerEngine::startWork);
    
    // Update menu state on timer changes
    connect(m_timerEngine, &TimerEngine::statusChanged, this, &TrayIcon::updateMenuState);
    connect(m_timerEngine, &TimerEngine::timeUpdated, this, &TrayIcon::updateMenuState);
    
    // App actions
    connect(m_quitAction, &QAction::triggered, qApp, &QApplication::quit);

    // Update Manager connections
    connect(m_checkUpdateAction, &QAction::triggered, this, &TrayIcon::onCheckUpdate);
    // connect(m_updateManager, &UpdateManager::updateAvailable, this, &TrayIcon::onUpdateAvailable);
    // connect(m_updateManager, &UpdateManager::noUpdateAvailable, this, &TrayIcon::onNoUpdateAvailable);
    // connect(m_updateManager, &UpdateManager::updateError, this, &TrayIcon::onUpdateError);
    // connect(m_updateManager, &UpdateManager::downloadProgressSignal, this, &TrayIcon::onDownloadProgress);
    // connect(m_updateManager, &UpdateManager::downloadFinished, this, &TrayIcon::onDownloadFinished);
}

void TrayIcon::showMessage(const QString &title, const QString &message) {
    m_trayIcon->showMessage(title, message);
}

void TrayIcon::onActivated(QSystemTrayIcon::ActivationReason reason) {
    if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
        emit showMainWindowRequested();
    }
}

void TrayIcon::updateMenuState() {
    QString status = m_timerEngine->statusText();
    bool isPaused = (status == "已暂停" || status == "准备就绪");
    
    m_startAction->setVisible(isPaused);
    m_pauseAction->setVisible(!isPaused);
    
    int secs = m_timerEngine->remainingSeconds();
    QString timeStr = QString("%1:%2")
        .arg(secs / 60, 2, 10, QChar('0'))
        .arg(secs % 60, 2, 10, QChar('0'));
    
    m_trayIcon->setToolTip(QString("DeskCare - %1\n%2")
        .arg(status)
        .arg(timeStr));
}

// --- Update Logic ---

void TrayIcon::onCheckUpdate() {
    // showMessage("检查更新", "正在连接服务器检查新版本...");
    m_updateManager->checkForUpdates(false);
}

void TrayIcon::onUpdateAvailable(const QString &version, const QString &changelog, const QString &url) {
    // Only show modal dialog for update available as it requires user action
    QMessageBox msgBox;
    msgBox.setWindowTitle("发现新版本 " + version);
    msgBox.setTextFormat(Qt::MarkdownText);
    msgBox.setText(QString("### 发现新版本: %1\n\n**更新内容:**\n%2\n\n是否立即更新？").arg(version, changelog));
    msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    msgBox.setDefaultButton(QMessageBox::Yes);
    msgBox.button(QMessageBox::Yes)->setText("立即更新");
    msgBox.button(QMessageBox::No)->setText("稍后提醒");
    
    if (msgBox.exec() == QMessageBox::Yes) {
        // showMessage("开始更新", "正在下载更新包，请稍候...");
        m_updateManager->startDownload(url);
    }
}

void TrayIcon::onNoUpdateAvailable() {
    // showMessage("检查更新", "当前已是最新版本。");
}

void TrayIcon::onUpdateError(const QString &error) {
    Q_UNUSED(error);
    // showMessage("更新错误", error);
}

void TrayIcon::onDownloadProgress(qint64 received, qint64 total) {
    // Optional: Update tooltip or show percentage in tray
    if (total > 0) {
        int percent = (received * 100) / total;
        if (percent % 20 == 0) { // Avoid spamming
             // m_trayIcon->setToolTip(QString("正在下载更新: %1%").arg(percent));
        }
    }
}

void TrayIcon::onDownloadFinished(const QString &filePath) {
    showMessage("下载完成", "正在启动安装程序...");
    launchUpdater(filePath);
}

void TrayIcon::launchUpdater(const QString &zipPath) {
    QString appDir = QCoreApplication::applicationDirPath();
    QString appName = "DeskCare.exe";
    QString updaterPath = appDir + "/Updater.exe";

    if (!QFile::exists(updaterPath)) {
        QMessageBox::critical(nullptr, "错误", "未找到更新程序 Updater.exe");
        return;
    }

    // Updater.exe <zip_path> <install_dir> <exe_name>
    QStringList args;
    args << zipPath << appDir << appName;

    if (QProcess::startDetached(updaterPath, args)) {
        QCoreApplication::quit();
    } else {
        QMessageBox::critical(nullptr, "错误", "无法启动更新程序");
    }
}
