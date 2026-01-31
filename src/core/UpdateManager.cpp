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

UpdateManager::UpdateManager(QObject *parent) : QObject(parent), m_networkManager(new QNetworkAccessManager(this)), m_currentReply(nullptr)
{
}

void UpdateManager::checkForUpdates(bool silent)
{
    m_silentCheck = silent;
    
    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
    }

    QUrl url(UPDATE_URL);
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork); // Disable cache
    
    m_currentReply = m_networkManager->get(request);
    connect(m_currentReply, &QNetworkReply::finished, this, &UpdateManager::onVersionCheckFinished);
}

void UpdateManager::onVersionCheckFinished()
{
    if (!m_currentReply) return;
    
    m_currentReply->deleteLater();
    
    if (m_currentReply->error() != QNetworkReply::NoError) {
        if (!m_silentCheck) {
            emit updateError("网络请求失败: " + m_currentReply->errorString());
        }
        m_currentReply = nullptr;
        return;
    }

    QByteArray data = m_currentReply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull() || !doc.isObject()) {
        if (!m_silentCheck) {
            emit updateError("无法解析版本信息");
        }
        m_currentReply = nullptr;
        return;
    }

    QJsonObject obj = doc.object();
    QString remoteVersion = obj["latest_version"].toString();
    QString currentVersion = APP_VERSION;

    if (isNewerVersion(remoteVersion, currentVersion)) {
        QString changelog = obj["changelog"].toString();
        QString url = obj["download_url"].toString();
        emit updateAvailable(remoteVersion, changelog, url);
    } else {
        if (!m_silentCheck) {
            emit noUpdateAvailable();
        }
    }
    
    m_currentReply = nullptr;
}

void UpdateManager::startDownload(const QString &url)
{
    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
    }

    QUrl qUrl(url);
    QNetworkRequest request(qUrl);
    m_currentReply = m_networkManager->get(request);
    
    connect(m_currentReply, &QNetworkReply::downloadProgress, this, &UpdateManager::downloadProgress);
    connect(m_currentReply, &QNetworkReply::finished, this, &UpdateManager::onDownloadFinished);
}

void UpdateManager::onDownloadFinished()
{
    if (!m_currentReply) return;
    m_currentReply->deleteLater();

    if (m_currentReply->error() != QNetworkReply::NoError) {
        emit updateError("下载失败: " + m_currentReply->errorString());
        m_currentReply = nullptr;
        return;
    }

    // Save to temp
    QString tempPath = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QString filePath = tempPath + "/DeskCare_Update.zip";
    
    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(m_currentReply->readAll());
        file.close();
        emit downloadFinished(filePath);
    } else {
        emit updateError("无法写入文件: " + filePath);
    }
    
    m_currentReply = nullptr;
}

bool UpdateManager::isNewerVersion(const QString &remoteVer, const QString &localVer)
{
    QStringList rParts = remoteVer.split(".");
    QStringList lParts = localVer.split(".");
    
    for (int i = 0; i < qMax(rParts.size(), lParts.size()); ++i) {
        int r = (i < rParts.size()) ? rParts[i].toInt() : 0;
        int l = (i < lParts.size()) ? lParts[i].toInt() : 0;
        
        if (r > l) return true;
        if (r < l) return false;
    }
    return false;
}
