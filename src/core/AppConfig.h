#ifndef APPCONFIG_H
#define APPCONFIG_H

#include <QObject>
#include <QSettings>
#include <QCoreApplication>
#include <QDir>

// ========================================================================
// AppConfig 类：应用程序配置管理
// ========================================================================
// 作用：负责读写应用程序的持久化配置（如是否开机自启）。
// 原理：使用 QSettings 类，它抽象了不同操作系统的配置存储方式：
// - Windows: 注册表 (Registry)
// - macOS: .plist 文件
// - Linux: .conf (ini) 文件
// ========================================================================
class AppConfig : public QObject
{
    Q_OBJECT
    
    // 开机自启属性
    // READ: 读取当前状态
    // WRITE: 修改状态（并写入注册表）
    // NOTIFY: 状态变更信号
    Q_PROPERTY(bool autoStart READ isAutoStart WRITE setAutoStart NOTIFY autoStartChanged)

public:
    explicit AppConfig(QObject *parent = nullptr);

    // 读取是否开机自启
    bool isAutoStart() const;
    
    // 设置是否开机自启
    void setAutoStart(bool autoStart);

signals:
    // 当开机自启状态改变时触发
    void autoStartChanged(bool autoStart);

private:
    // Windows 注册表路径，用于设置开机自启
    // HKCU\Software\Microsoft\Windows\CurrentVersion\Run 是 Windows 标准的自启动项位置
    const QString REG_RUN_KEY = "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run";
    
    // 应用程序名称 (作为注册表键名)
    const QString APP_NAME = "DeskCare";
};

#endif // APPCONFIG_H
