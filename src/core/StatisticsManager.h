#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QSettings>

class StatisticsManager : public QObject {
    Q_OBJECT

public:
    explicit StatisticsManager(QObject *parent = nullptr);
    void reportStartup();

private:
    QString getMachineId();
    QString calculateHash(const QString& input);
    
    QNetworkAccessManager *m_networkManager;
    const QString REPORT_URL = "http://47.101.52.0/api/report";
    const QString SALT = "DeskCare_Salt_2026";
};
