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

public:
    explicit TimerEngine(QObject *parent = nullptr);

    int remainingSeconds() const;
    QString statusText() const;

public slots:
    // 开始工作计时（重置为45分钟）
    void startWork();
    // 贪睡模式（重置为5分钟）
    void snooze();
    // 暂停/停止计时
    void stop();

signals:
    // 时间更新信号（每秒触发）
    void timeUpdated();
    // 状态改变信号
    void statusChanged();
    // 倒计时结束，触发提醒
    void reminderTriggered();

private slots:
    void onTick();

private:
    QTimer *m_timer;
    int m_remainingSecs;
    const int m_workDuration = 45 * 60; // 45分钟
    const int m_snoozeDuration = 5 * 60; // 5分钟
    QString m_status;
};
