#include "UpdateManager.h"
#if defined(_MSC_VER) && (_MSC_VER >= 1600)
# pragma execution_character_set("utf-8")
#endif
#include "Version.h"
#include <QJsonDocument>
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QCoreApplication>
#include <QProcess>

// Config
const QString UPDATE_URL = "http://47.101.52.0/updates/version.json";

#include <QNetworkProxy>

UpdateManager::UpdateManager(QObject *parent) : QObject(parent), m_networkManager(new QNetworkAccessManager(this)), m_currentReply(nullptr)
{
    // Disable proxy to speed up connection (avoids Windows auto-detect delay)
    m_networkManager->setProxy(QNetworkProxy::NoProxy);
}

QString UpdateManager::currentVersion() const
{
    return Version::getCurrentVersion();
}

void UpdateManager::checkForUpdates(bool silent)
{
    qDebug() << "[UpdateManager] checkForUpdates called. Silent:" << silent;

    // Prevent crash: If a request is running, disconnect it before aborting
    // This ensures onVersionCheckFinished is NOT called, preventing double-deletion
    // and accessing m_currentReply after it has been set to nullptr.
    if (m_currentReply) {
        qDebug() << "[UpdateManager] Aborting pending request.";
        m_currentReply->disconnect(this);
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }

    m_silentCheck = silent;

    QUrl url(UPDATE_URL);
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork); // Disable cache
    request.setTransferTimeout(5000); // 5 seconds timeout
    
    m_currentReply = m_networkManager->get(request);
    connect(m_currentReply, &QNetworkReply::finished, this, &UpdateManager::onVersionCheckFinished);
}

void UpdateManager::onVersionCheckFinished()
{
    if (!m_currentReply) {
        qDebug() << "[UpdateManager] onVersionCheckFinished called but m_currentReply is null (aborted?)";
        return;
    }
    
    // Take ownership of the reply to prevent re-entrancy issues or double-deletion
    // if checkForUpdates is called inside a slot connected to signals emitted here.
    QNetworkReply *reply = m_currentReply;
    m_currentReply = nullptr;
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        qDebug() << "[UpdateManager] Network error:" << reply->errorString();
        if (!m_silentCheck) {
            emit updateError("检查更新失败: " + reply->errorString());
        }
        return;
    }

    QByteArray data = reply->readAll();
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
    
    if (parseError.error != QJsonParseError::NoError) {
        qDebug() << "[UpdateManager] JSON parse error:" << parseError.errorString();
        if (!m_silentCheck) {
            emit updateError("无法解析版本信息: " + parseError.errorString());
        }
        return;
    }

    QJsonObject obj = doc.object();
    
    // Debug: Print full JSON response
    qDebug() << "[UpdateManager] Received JSON:" << doc.toJson(QJsonDocument::Compact);

    // Support both "version" and "latest_version" fields
    QString remoteVersion = obj["version"].toString();
    if (remoteVersion.isEmpty()) {
        remoteVersion = obj["latest_version"].toString();
    }
    
    QString changelog = obj["changelog"].toString();
    QString downloadUrl = obj["download_url"].toString();
    
    if (remoteVersion.isEmpty()) {
        qDebug() << "[UpdateManager] Remote version is empty.";
        if (!m_silentCheck) {
            emit updateError("版本信息无效");
        }
        return;
    }

    qDebug() << "[UpdateManager] Remote version:" << remoteVersion << "Local:" << Version::getCurrentVersion();

    if (isNewerVersion(remoteVersion, Version::getCurrentVersion())) {
        emit updateAvailable(remoteVersion, changelog, downloadUrl);
    } else {
        if (!m_silentCheck) {
            emit noUpdateAvailable();
        }
    }
}

void UpdateManager::startDownload(const QString &url)
{
    // Simple download logic - in a real app might want a separate DownloadManager or handle redirects
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::downloadProgress, this, &UpdateManager::downloadProgress);
    connect(reply, &QNetworkReply::finished, this, &UpdateManager::onDownloadFinished);
}

void UpdateManager::onDownloadFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        emit updateError("下载失败: " + reply->errorString());
        return;
    }
    
    // Save to temp file
    QString tempPath = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/DeskCare_Update.zip";
    QFile file(tempPath);
    if (!file.open(QIODevice::WriteOnly)) {
        emit updateError("无法保存更新文件");
        return;
    }
    
    file.write(reply->readAll());
    file.close();
    
    emit downloadFinished(tempPath);
}

bool UpdateManager::isNewerVersion(const QString &remoteVer, const QString &localVer)
{
    // Simple string comparison for now, assuming format x.y.z
    // For robust comparison, should split by '.' and compare integers
    QStringList remoteParts = remoteVer.split('.');
    QStringList localParts = localVer.split('.');
    
    int count = qMin(remoteParts.size(), localParts.size());
    for (int i = 0; i < count; ++i) {
        int r = remoteParts[i].toInt();
        int l = localParts[i].toInt();
        if (r > l) return true;
        if (r < l) return false;
    }
    
    return remoteParts.size() > localParts.size();
}
