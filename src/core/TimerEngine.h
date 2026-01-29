#pragma once
#include <QObject>
#include <QTimer>
#include <QDateTime>

// 计时与状态引擎：负责核心倒计时逻辑
class TimerEngine : public QObject
{
    Q_OBJECT
    // 暴露给QML的属性：剩余秒数
    Q_PROPERTY(int remainingSeconds READ remainingSeconds NOTIFY timeUpdated)
    // 暴露给QML的属性：当前状态描述
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    // 暴露给QML的属性：工作间隔（分钟）
    Q_PROPERTY(int workDurationMinutes READ workDurationMinutes WRITE setWorkDurationMinutes NOTIFY workDurationMinutesChanged)
    // 暴露给QML的属性：预计完成时间 (HH:mm)
    Q_PROPERTY(QString estimatedFinishTime READ estimatedFinishTime NOTIFY timeUpdated)

public:
    explicit TimerEngine(QObject *parent = nullptr);

    int remainingSeconds() const;
    QString statusText() const;
    int workDurationMinutes() const;
    QString estimatedFinishTime() const;

public slots:
    // 设置工作间隔（分钟）
    void setWorkDurationMinutes(int minutes);
    // 开始工作计时（重置为设定间隔）
    void startWork();
    // 贪睡模式（重置为5分钟）
    void snooze();
    // 暂停/停止计时
    void stop();
    // 切换暂停/继续状态
    Q_INVOKABLE void togglePause();

signals:
    // 时间更新信号（每秒触发）
    void timeUpdated();
    // 状态改变信号
    void statusChanged();
    // 倒计时结束，触发提醒
    void reminderTriggered();
    // 工作间隔变更信号
    void workDurationMinutesChanged();
    // 休息结束信号，带有时长（秒）
    void breakFinished(int durationSeconds);

private slots:
    void onTick();

private:
    QTimer *m_timer;
    int m_remainingSecs;
    int m_workDuration; // 单位：秒
    const int m_snoozeDuration = 5 * 60; // 5分钟
    QString m_status;
    QDateTime m_breakStartTime; // 休息开始时间
};
