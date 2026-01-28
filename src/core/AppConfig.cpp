#include "AppConfig.h"
#include <QDebug>

AppConfig::AppConfig(QObject *parent) : QObject(parent)
{
}

bool AppConfig::isAutoStart() const
{
#ifdef Q_OS_WIN
    QSettings settings(REG_RUN_KEY, QSettings::NativeFormat);
    return settings.contains(APP_NAME);
#else
    return false;
#endif
}

void AppConfig::setAutoStart(bool autoStart)
{
#ifdef Q_OS_WIN
    QSettings settings(REG_RUN_KEY, QSettings::NativeFormat);
    if (autoStart) {
        QString appPath = QCoreApplication::applicationFilePath();
        QString nativePath = QDir::toNativeSeparators(appPath);
        // Add quotes to handle paths with spaces
        settings.setValue(APP_NAME, "\"" + nativePath + "\"");
    } else {
        settings.remove(APP_NAME);
    }
    emit autoStartChanged(autoStart);
#else
    Q_UNUSED(autoStart);
#endif
}
