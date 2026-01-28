#ifndef APPCONFIG_H
#define APPCONFIG_H

#include <QObject>
#include <QSettings>
#include <QCoreApplication>
#include <QDir>

class AppConfig : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool autoStart READ isAutoStart WRITE setAutoStart NOTIFY autoStartChanged)

public:
    explicit AppConfig(QObject *parent = nullptr);

    bool isAutoStart() const;
    void setAutoStart(bool autoStart);

signals:
    void autoStartChanged(bool autoStart);

private:
    const QString REG_RUN_KEY = "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run";
    const QString APP_NAME = "ExerciseReminder";
};

#endif // APPCONFIG_H
