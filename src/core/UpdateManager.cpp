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

UpdateManager::UpdateManager(QObject *parent) : QObject(parent), 
    m_networkManager(new QNetworkAccessManager(this)), 
    m_currentReply(nullptr),
    m_hasUpdate(false),
    m_downloadProgress(0.0)
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

void UpdateManager::resetStatus()
{
    m_updateStatus = "";
    m_downloadProgress = 0.0;
    emit updateStatusChanged();
    emit downloadProgressChanged();
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
        m_hasUpdate = true;
        m_remoteVersion = remoteVersion;
        m_changelog = changelog;
        m_downloadUrl = downloadUrl;
        
        emit hasUpdateChanged();
        emit updateAvailable(remoteVersion, changelog, downloadUrl);
    } else {
        m_hasUpdate = false;
        emit hasUpdateChanged();
        
        if (!m_silentCheck) {
            emit noUpdateAvailable();
        }
    }
}

void UpdateManager::startDownload(const QString &url)
{
    // Use stored URL if argument is empty
    QString targetUrl = url;
    if (targetUrl.isEmpty()) {
        targetUrl = m_downloadUrl;
    }
    
    if (targetUrl.isEmpty()) {
        emit updateError("下载地址无效");
        return;
    }

    m_updateStatus = "正在连接下载服务器...";
    emit updateStatusChanged();
    
    m_downloadProgress = 0.0;
    emit downloadProgressChanged();

    // Simple download logic
    QNetworkRequest request(targetUrl);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::downloadProgress, this, &UpdateManager::onDownloadProgress);
    connect(reply, &QNetworkReply::finished, this, &UpdateManager::onDownloadFinished);
}

void UpdateManager::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (bytesTotal > 0) {
        m_downloadProgress = (double)bytesReceived / (double)bytesTotal;
        emit downloadProgressChanged();
        emit downloadProgressSignal(bytesReceived, bytesTotal);
        
        m_updateStatus = QString("正在下载更新包 (%1%)...").arg(int(m_downloadProgress * 100));
        emit updateStatusChanged();
    }
}

void UpdateManager::onDownloadFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        m_updateStatus = "下载失败: " + reply->errorString();
        emit updateStatusChanged();
        emit updateError(m_updateStatus);
        return;
    }
    
    // Save to temp file
    m_tempFilePath = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/DeskCare_Update.zip";
    
    // Delete existing file if present
    QFile::remove(m_tempFilePath);
    
    QFile file(m_tempFilePath);
    if (!file.open(QIODevice::WriteOnly)) {
        m_updateStatus = "无法保存更新文件";
        emit updateStatusChanged();
        emit updateError(m_updateStatus);
        return;
    }
    
    file.write(reply->readAll());
    file.close();
    
    m_updateStatus = "下载完成，正在准备安装...";
    emit updateStatusChanged();
    emit downloadFinished(m_tempFilePath);
    
    // Auto start install after download? 
    // Usually better to let UI trigger it or do it here. 
    // Since the flow is user confirmed -> download -> install, we can proceed.
    startInstall();
}

void UpdateManager::startInstall()
{
    if (m_tempFilePath.isEmpty() || !QFile::exists(m_tempFilePath)) {
        emit updateError("更新文件不存在");
        return;
    }

    m_updateStatus = "正在启动更新程序...";
    emit updateStatusChanged();

    QString program = QCoreApplication::applicationDirPath() + "/Updater.exe";
    QStringList arguments;
    arguments << m_tempFilePath; // Zip path
    arguments << QCoreApplication::applicationDirPath(); // Install dir
    arguments << "DeskCare.exe"; // Exe name (to restart)

    qDebug() << "Starting Updater:" << program << arguments;

    if (!QProcess::startDetached(program, arguments)) {
        emit updateError("无法启动更新程序");
        return;
    }

    QCoreApplication::quit();
}

bool UpdateManager::isNewerVersion(const QString &remoteVer, const QString &localVer)
{
    // Simple string comparison for now, assuming format x.y.z
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
