#ifndef UPDATEMANAGER_H
#define UPDATEMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>

class UpdateManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentVersion READ currentVersion CONSTANT)
    Q_PROPERTY(QString remoteVersion READ remoteVersion NOTIFY hasUpdateChanged)
    Q_PROPERTY(bool hasUpdate READ hasUpdate NOTIFY hasUpdateChanged)
    Q_PROPERTY(QString updateStatus READ updateStatus NOTIFY updateStatusChanged)
    Q_PROPERTY(double downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)

public:
    explicit UpdateManager(QObject *parent = nullptr);
    Q_INVOKABLE void checkForUpdates(bool silent = true);
    Q_INVOKABLE void startInstall(); // Start the updater process
    
    QString currentVersion() const;
    QString remoteVersion() const { return m_remoteVersion; }
    bool hasUpdate() const { return m_hasUpdate; }
    QString updateStatus() const { return m_updateStatus; }
    double downloadProgress() const { return m_downloadProgress; }

signals:
    void updateAvailable(const QString &version, const QString &changelog, const QString &downloadUrl);
    void noUpdateAvailable();
    void updateError(const QString &error);
    void downloadProgressSignal(qint64 bytesReceived, qint64 bytesTotal); // Renamed to avoid clash
    void downloadFinished(const QString &filePath);
    
    void hasUpdateChanged();
    void updateStatusChanged();
    void downloadProgressChanged();

public slots:
    void startDownload(const QString &url);

private slots:
    void onVersionCheckFinished();
    void onDownloadFinished();
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);

private:
    QNetworkAccessManager *m_networkManager;
    QNetworkReply *m_currentReply;
    bool m_silentCheck;
    
    bool m_hasUpdate;
    QString m_updateStatus;
    double m_downloadProgress;
    
    // Stored update info
    QString m_remoteVersion;
    QString m_changelog;
    QString m_downloadUrl;
    QString m_tempFilePath;

    // Compare version strings "1.0.0" vs "1.1.0"
    // Returns true if remote > local
    bool isNewerVersion(const QString &remoteVer, const QString &localVer);
};

#endif // UPDATEMANAGER_H
