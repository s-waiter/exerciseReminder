#pragma once
#include <QObject>
#include <QTimer>
#include <QDateTime>

// ========================================================================
// TimerEngine 类：核心业务逻辑引擎
// ========================================================================
// 作用：负责倒计时、状态管理（工作中、休息中、暂停等）以及进度计算。
// 继承：QObject 是所有 Qt 对象的基类，提供了信号与槽、属性系统、事件处理等核心功能。
// ========================================================================
class TimerEngine : public QObject
{
    // Q_OBJECT 宏：
    // 这是 Qt 的核心宏，必须放在类定义的私有区域（通常是第一行）。
    // 它启用元对象系统 (Meta-Object System)，支持信号 (signals)、槽 (slots) 和属性 (Q_PROPERTY)。
    // 编译时，MOC (Meta-Object Compiler) 会扫描此宏并生成额外的 C++ 代码 (moc_TimerEngine.cpp)。
    Q_OBJECT

    // ========================================================================
    // Q_PROPERTY 属性系统
    // ========================================================================
    // Q_PROPERTY 允许将 C++ 的成员变量暴露给 QML (前端)。
    // 语法：Q_PROPERTY(类型 属性名 READ 读函数 [WRITE 写函数] NOTIFY 通知信号)
    // - READ: QML 读取属性时调用的 C++ 函数。
    // - WRITE: QML 修改属性时调用的 C++ 函数 (可选，只读属性不需要)。
    // - NOTIFY: 当属性值发生变化时，C++ 发出的信号。QML 依靠这个信号自动更新界面 (数据绑定)。

    // 1. 剩余秒数 (只读)
    Q_PROPERTY(int remainingSeconds READ remainingSeconds NOTIFY timeUpdated)
    
    // 2. 当前状态描述 (只读，如 "工作中", "请休息")
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    
    // 3. 工作间隔 (读写，单位：分钟)
    // QML 可以读取当前设置，也可以修改它。修改后会触发 workDurationMinutesChanged 信号。
    Q_PROPERTY(int workDurationMinutes READ workDurationMinutes WRITE setWorkDurationMinutes NOTIFY workDurationMinutesChanged)
    
    // 4. 预计完成时间 (只读，格式 "HH:mm")
    Q_PROPERTY(QString estimatedFinishTime READ estimatedFinishTime NOTIFY timeUpdated)

    // 5. 当前会话总时长 (只读，单位：秒)
    // 用于进度条计算：progress = remainingSeconds / currentSessionTotalTime
    Q_PROPERTY(int currentSessionTotalTime READ currentSessionTotalTime NOTIFY currentSessionTotalTimeChanged)

public:
    // 构造函数
    // parent: 父对象指针。Qt 使用对象树机制管理内存。
    // 当父对象被销毁时，所有子对象会自动被销毁，防止内存泄漏。
    explicit TimerEngine(QObject *parent = nullptr);

    // Getter 函数 (对应 Q_PROPERTY 的 READ)
    int remainingSeconds() const;
    QString statusText() const;
    int workDurationMinutes() const;
    QString estimatedFinishTime() const;
    int currentSessionTotalTime() const;

// ========================================================================
// Slots (槽函数)
// ========================================================================
// 槽是普通的 C++ 成员函数，但可以被“连接”到信号上。
// Q_INVOKABLE 宏：
// 标记一个函数可以被 Qt 元对象系统调用，这意味着它可以在 QML 中直接被调用。
// 普通的 public slots 默认也是 Q_INVOKABLE 的。
public slots:
    // 设置工作间隔（分钟）
    void setWorkDurationMinutes(int minutes);
    
    // 开始工作计时（重置为设定间隔）
    void startWork();
    
    // 贪睡模式（重置为5分钟）
    void snooze();
    
    // 暂停/停止计时
    void stop();
    
    // 切换暂停/继续状态 (供 QML 按钮点击调用)
    Q_INVOKABLE void togglePause();

// ========================================================================
// Signals (信号)
// ========================================================================
// 信号用于通知外部“发生了某事”。
// 只需要在头文件中声明，不需要在 .cpp 中实现 (MOC 会自动生成实现)。
// 使用 emit 关键字触发信号，例如: emit timeUpdated();
signals:
    // 时间更新信号（每秒触发一次，用于刷新倒计时显示）
    void timeUpdated();
    
    // 状态改变信号（当从“工作中”变为“休息中”等情况触发）
    void statusChanged();
    
    // 倒计时结束，触发提醒（用于显示全屏覆盖窗口）
    void reminderTriggered();
    
    // 工作间隔变更信号
    void workDurationMinutesChanged();
    
    // 当前会话总时长变更信号
    void currentSessionTotalTimeChanged();
    
    // 休息结束信号，带有时长（秒），用于统计或日志
    void breakFinished(int durationSeconds);

private slots:
    // 内部槽函数：处理 QTimer 的每秒超时事件
    void onTick();

private:
    // 成员变量
    QTimer *m_timer;      // Qt 定时器对象
    int m_remainingSecs;  // 剩余秒数
    int m_workDuration;   // 设定的工作时长 (单位：秒)
    int m_currentSessionTotal; // 当前正在进行的会话总时长 (用于进度条分母，防止中途修改设置导致进度条跳变)
    
    const int m_snoozeDuration = 5 * 60; // 贪睡时长常量 (5分钟)
    QString m_status;     // 当前状态文本
    QDateTime m_breakStartTime; // 休息开始时间点 (用于计算休息了多久)
};
