#include "StatisticsManager.h"
#include "Version.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkInterface>
#include <QCryptographicHash>
#include <QCoreApplication>
#include <QTimer>
#include <QDebug>
#include <QUrlQuery>

StatisticsManager::StatisticsManager(QObject *parent) : QObject(parent) {
    m_networkManager = new QNetworkAccessManager(this);
}

void StatisticsManager::reportStartup() {
    // 延时上报，避免影响启动速度
    QTimer::singleShot(2000, this, [this]() {
        QString uid = getMachineId();
        QString version = Version::getCurrentVersion();
        
        // 构造 URL 参数
        QUrl url(REPORT_URL);
        QUrlQuery query;
        query.addQueryItem("uid", uid);
        query.addQueryItem("ver", version);
        query.addQueryItem("app", "DeskCare");
        url.setQuery(query);

        QNetworkRequest request(url);
        // 设置 User-Agent 方便日志识别
        request.setHeader(QNetworkRequest::UserAgentHeader, "DeskCare-Client/1.0");

        qDebug() << "Reporting stats to:" << url.toString();

        // 发送 GET 请求 (日志统计模式)
        QNetworkReply *reply = m_networkManager->get(request);
        
        connect(reply, &QNetworkReply::finished, this, [reply]() {
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            if (reply->error() == QNetworkReply::NoError) {
                qDebug() << "Stats reported successfully. Status:" << statusCode;
            } else {
                qWarning() << "Stats report failed:" << reply->errorString() << "Status:" << statusCode;
            }
            reply->deleteLater();
        });
    });
}

QString StatisticsManager::getMachineId() {
    // 优先尝试从注册表/配置文件读取缓存的 ID
    QSettings settings("DeskCare", "Statistics");
    QString cachedId = settings.value("MachineId").toString();
    if (!cachedId.isEmpty()) {
        return cachedId;
    }

    // 获取主网卡 MAC 地址
    QString macAddress;
    foreach(QNetworkInterface interface, QNetworkInterface::allInterfaces()) {
        // 过滤回环接口、非物理接口等
        if (!(interface.flags() & QNetworkInterface::IsLoopBack) &&
            (interface.flags() & QNetworkInterface::IsUp) &&
            !interface.hardwareAddress().isEmpty()) {
            macAddress = interface.hardwareAddress();
            break; // 取第一个有效的
        }
    }

    if (macAddress.isEmpty()) {
        macAddress = "unknown_device";
    }

    // 计算哈希: SHA256(MAC + Salt)
    QString hash = calculateHash(macAddress + SALT);
    
    // 缓存 ID
    settings.setValue("MachineId", hash);
    
    return hash;
}

QString StatisticsManager::calculateHash(const QString& input) {
    QByteArray data = input.toUtf8();
    QByteArray hash = QCryptographicHash::hash(data, QCryptographicHash::Sha256);
    return hash.toHex();
}
