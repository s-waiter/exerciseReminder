#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QSettings>
#include <QDate>
#include <QTimer>
#include <QNetworkReply>

class StatisticsManager : public QObject {
    Q_OBJECT

public:
    explicit StatisticsManager(QObject *parent = nullptr);
    void reportStartup();

private slots:
    void checkNewDay();
    void onReportFinished(QNetworkReply* reply);
    void retryReport();

private:
    void reportUsage();
    QString getMachineId();
    QString calculateHash(const QString& input);
    
    QNetworkAccessManager *m_networkManager;
    const QString REPORT_URL = "http://47.101.52.0/api/report";
    const QString SALT = "DeskCare_Salt_2026";

    QDate m_lastReportDate;
    QTimer *m_dailyCheckTimer;
    QTimer *m_retryTimer;
    int m_retryCount = 0;
    const int MAX_RETRIES = 10; // Max retries per attempt sequence
};
