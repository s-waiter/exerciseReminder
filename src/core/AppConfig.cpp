#include "AppConfig.h"
#include <QDebug>
#include <QCoreApplication>
#include <QDir>

// ========================================================================
// 构造函数
// ========================================================================
// 初始化 AppConfig 对象。
// parent 参数用于 Qt 的对象树内存管理机制。
AppConfig::AppConfig(QObject *parent) : QObject(parent)
{
}

// ========================================================================
// 读取：是否开机自启
// ========================================================================
// 检查系统中是否已经设置了开机自启。
bool AppConfig::isAutoStart() const
{
// #ifdef Q_OS_WIN 是 Qt 的跨平台宏，仅在 Windows 编译时包含此代码块。
#ifdef Q_OS_WIN
    // QSettings::NativeFormat 在 Windows 上意味着读写注册表。
    // REG_RUN_KEY 是 "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
    QSettings settings(REG_RUN_KEY, QSettings::NativeFormat);
    
    // 检查注册表中是否存在名为 APP_NAME ("ExerciseReminder") 的键值
    return settings.contains(APP_NAME);
#else
    // 非 Windows 平台暂时返回 false
    return false;
#endif
}

// ========================================================================
// 设置：是否开机自启
// ========================================================================
// 修改系统的开机自启设置。
// autoStart: true 为开启，false 为关闭
void AppConfig::setAutoStart(bool autoStart)
{
#ifdef Q_OS_WIN
    // 打开注册表的 Run 键
    QSettings settings(REG_RUN_KEY, QSettings::NativeFormat);
    
    if (autoStart) {
        // 获取当前应用程序的可执行文件绝对路径 (例如 "C:/Program Files/MyApp/MyApp.exe")
        QString appPath = QCoreApplication::applicationFilePath();
        
        // 将路径分隔符转换为当前系统原生格式 (Windows 下 "/" -> "\")
        QString nativePath = QDir::toNativeSeparators(appPath);
        
        // 写入注册表。
        // 注意：路径如果有空格，必须用双引号括起来，否则 Windows 启动时可能无法正确解析。
        // 例如： "\"C:\\Program Files\\My App\\app.exe\""
        settings.setValue(APP_NAME, "\"" + nativePath + "\"");
    } else {
        // 从注册表中移除该键值，取消自启
        settings.remove(APP_NAME);
    }
    
    // 发送信号通知 QML 界面，属性值已更改。
    // 虽然这里是我们自己设置的，但在某些情况下（如外部修改注册表），
    // 保持 UI 和底层状态同步是个好习惯。
    emit autoStartChanged(autoStart);
#else
    // Q_UNUSED 宏用于消除编译器关于 "未使用参数" 的警告。
    // 在非 Windows 平台上，autoStart 参数没有被使用。
    Q_UNUSED(autoStart);
#endif
}
