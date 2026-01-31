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

public:
    explicit UpdateManager(QObject *parent = nullptr);
    Q_INVOKABLE void checkForUpdates(bool silent = true);
    
    QString currentVersion() const;

signals:
    void updateAvailable(const QString &version, const QString &changelog, const QString &downloadUrl);
    void noUpdateAvailable();
    void updateError(const QString &error);
    void downloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void downloadFinished(const QString &filePath);

public slots:
    void startDownload(const QString &url);

private slots:
    void onVersionCheckFinished();
    void onDownloadFinished();

private:
    QNetworkAccessManager *m_networkManager;
    QNetworkReply *m_currentReply;
    bool m_silentCheck;
    
    // Compare version strings "1.0.0" vs "1.1.0"
    // Returns true if remote > local
    bool isNewerVersion(const QString &remoteVer, const QString &localVer);
};

#endif // UPDATEMANAGER_H
