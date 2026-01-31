#pragma once
#include <QObject>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include "../core/TimerEngine.h"
#include "../core/UpdateManager.h" // Include UpdateManager

class TrayIcon : public QObject {
    Q_OBJECT

public:
    explicit TrayIcon(TimerEngine *timerEngine, UpdateManager *updateManager, QObject *parent = nullptr);
    ~TrayIcon();

    void showMessage(const QString &title, const QString &message);

signals:
    void showMainWindowRequested();

private slots:
    void onActivated(QSystemTrayIcon::ActivationReason reason);
    void updateMenuState();
    
    // Update slots
    void onCheckUpdate();
    void onUpdateAvailable(const QString &version, const QString &changelog, const QString &url);
    void onNoUpdateAvailable();
    void onUpdateError(const QString &error);
    void onDownloadProgress(qint64 received, qint64 total);
    void onDownloadFinished(const QString &filePath);

private:
    QSystemTrayIcon *m_trayIcon;
    QMenu *m_trayMenu;
    TimerEngine *m_timerEngine;
    UpdateManager *m_updateManager; // Manager instance

    QAction *m_startAction;
    QAction *m_pauseAction;
    QAction *m_napAction; // 午休模式
    QAction *m_skipAction;
    QAction *m_resetAction;
    QAction *m_quitAction;
    QAction *m_checkUpdateAction; // New action

    void createMenu();
    void setupConnections();
    
    // Helper to launch updater
    void launchUpdater(const QString &zipPath);
};
