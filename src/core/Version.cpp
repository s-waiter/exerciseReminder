#include "Version.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QCoreApplication>
#include <QDebug>
#include <QDir>

QString Version::getCurrentVersion()
{
    static QString versionCache;
    if (!versionCache.isEmpty()) {
        return versionCache;
    }

    // Default version if file not found
    QString versionString = "1.0.0";

    // Search paths for version_info.json
    // 1. Current working directory (often project root in IDE)
    // 2. Application executable directory (deployed app)
    // 3. One level up (shadow build)
    QStringList paths = {
        "version_info.json",
        QCoreApplication::applicationDirPath() + "/version_info.json",
        "../version_info.json",
        "../../version_info.json",
        // Absolute path fallback for this specific dev environment as requested/implied
        "c:/Users/admin/Desktop/trae/DeskCare/version_info.json"
    };

    for (const QString &path : paths) {
        QFile file(path);
        if (file.exists() && file.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            if (!doc.isNull() && doc.isObject()) {
                QJsonObject obj = doc.object();
                if (obj.contains("major") && obj.contains("minor") && obj.contains("patch")) {
                    int major = obj["major"].toInt();
                    int minor = obj["minor"].toInt();
                    int patch = obj["patch"].toInt();
                    versionString = QString("%1.%2.%3").arg(major).arg(minor).arg(patch);
                    qDebug() << "Loaded version from:" << path << "Version:" << versionString;
                    versionCache = versionString;
                    return versionString;
                }
            }
            file.close();
        }
    }

    qWarning() << "Could not load version_info.json from any search path. Using default:" << versionString;
    versionCache = versionString;
    return versionString;
}
