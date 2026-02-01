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
    // 自动修复逻辑：
    // 检查注册表中是否已经开启了自启，但缺少 --autostart 参数（旧版本残留）
    // 如果是，则重新写入带参数的正确值，确保用户升级后能享受到新功能。
#ifdef Q_OS_WIN
    if (isAutoStart()) {
        QSettings settings(REG_RUN_KEY, QSettings::NativeFormat);
        QString currentValue = settings.value(APP_NAME).toString();
        
        // 获取当前期望的完整注册表值
        QString appPath = QCoreApplication::applicationFilePath();
        QString nativePath = QDir::toNativeSeparators(appPath);
        QString expectedValue = "\"" + nativePath + "\" --autostart";

        // 如果当前值与期望值不一致（包括路径改变、参数缺失等情况），则更新
        // 这也解决了文件夹重命名后自启路径失效的问题
        if (currentValue != expectedValue) {
            qDebug() << "Auto-start registry key mismatch (Path/Args). Updating...";
            setAutoStart(true); 
        }
    }
#endif
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
// 读取/设置：强制运动模式
// ========================================================================
bool AppConfig::isForcedExercise() const
{
    QSettings settings("TraeAI", "DeskCare");
    return settings.value("forcedExercise", false).toBool();
}

void AppConfig::setForcedExercise(bool enabled)
{
    QSettings settings("TraeAI", "DeskCare");
    if (isForcedExercise() != enabled) {
        settings.setValue("forcedExercise", enabled);
        emit forcedExerciseChanged(enabled);
    }
}

// ========================================================================
// 读取/设置：强制运动时长
// ========================================================================
int AppConfig::forcedExerciseDuration() const
{
    QSettings settings("TraeAI", "DeskCare");
    int val = settings.value("forcedExerciseDuration", 1).toInt();
    if (val < 1) val = 1;
    if (val > 5) val = 5;
    return val;
}

void AppConfig::setForcedExerciseDuration(int minutes)
{
    if (minutes < 1 || minutes > 5) return;
    
    QSettings settings("TraeAI", "DeskCare");
    if (forcedExerciseDuration() != minutes) {
        settings.setValue("forcedExerciseDuration", minutes);
        emit forcedExerciseDurationChanged(minutes);
    }
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
        // 添加 --autostart 参数以便区分启动模式
        settings.setValue(APP_NAME, "\"" + nativePath + "\" --autostart");
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
