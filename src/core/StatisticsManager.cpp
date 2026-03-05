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
    
    // 初始化重试定时器
    m_retryTimer = new QTimer(this);
    m_retryTimer->setSingleShot(true);
    connect(m_retryTimer, &QTimer::timeout, this, &StatisticsManager::reportUsage);

    // 初始化每日检查定时器 (每小时检查一次)
    m_dailyCheckTimer = new QTimer(this);
    m_dailyCheckTimer->setInterval(60 * 60 * 1000); 
    connect(m_dailyCheckTimer, &QTimer::timeout, this, &StatisticsManager::checkNewDay);
    m_dailyCheckTimer->start();
}

void StatisticsManager::reportStartup() {
    // 延时上报，避免影响启动速度
    QTimer::singleShot(2000, this, &StatisticsManager::reportUsage);
}

void StatisticsManager::checkNewDay() {
    if (m_lastReportDate != QDate::currentDate()) {
        qDebug() << "New day detected. Reporting usage...";
        // 重置重试计数器，确保新的一天能重新尝试
        m_retryCount = 0; 
        reportUsage();
    }
}

void StatisticsManager::reportUsage() {
    // 如果今天已经成功上报过，且不是重试机制触发的(通常重试不会改变日期，除非跨天了)，则跳过
    // 但为了保险起见，如果当前日期 > 上次上报日期，我们就报
    if (m_lastReportDate == QDate::currentDate()) {
        // 今天已经报过了
        return;
    }

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

    // 发送 GET 请求
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onReportFinished(reply);
        reply->deleteLater();
    });
}

void StatisticsManager::onReportFinished(QNetworkReply* reply) {
    if (!reply) return;

    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    if (reply->error() == QNetworkReply::NoError && (statusCode == 200 || statusCode == 0)) {
        qDebug() << "Stats reported successfully. Status:" << statusCode;
        m_lastReportDate = QDate::currentDate();
        m_retryCount = 0; // 重置重试次数
    } else {
        qWarning() << "Stats report failed:" << reply->errorString() << "Status:" << statusCode;
        retryReport();
    }
}

void StatisticsManager::retryReport() {
    if (m_retryCount < MAX_RETRIES) {
        m_retryCount++;
        // 指数退避策略: 10s, 30s, 60s, 2m, 5m...
        int delay = 10000 * m_retryCount; 
        if (delay > 300000) delay = 300000; // 最大间隔 5分钟

        qDebug() << "Will retry reporting in" << delay << "ms (Attempt" << m_retryCount << ")";
        m_retryTimer->start(delay);
    } else {
        qWarning() << "Max retries reached for stats reporting. Giving up for now.";
    }
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
