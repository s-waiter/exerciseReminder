#include "TimerEngine.h"
#include <QDebug>

TimerEngine::TimerEngine(QObject *parent) 
    : QObject(parent)
    , m_workDuration(45 * 60) // 默认45分钟
    , m_remainingSecs(45 * 60)
{
    m_timer = new QTimer(this);
    m_timer->setInterval(1000); // 1秒间隔
    connect(m_timer, &QTimer::timeout, this, &TimerEngine::onTick);
    
    // 初始化状态
    m_status = "准备就绪";
    // 默认直接开始工作计时
    startWork(); 
}

int TimerEngine::remainingSeconds() const { return m_remainingSecs; }

QString TimerEngine::statusText() const { return m_status; }

int TimerEngine::workDurationMinutes() const {
    return m_workDuration / 60;
}

QString TimerEngine::estimatedFinishTime() const {
    if (m_status == "已暂停") return "--:--";
    return QDateTime::currentDateTime().addSecs(m_remainingSecs).toString("HH:mm");
}

void TimerEngine::setWorkDurationMinutes(int minutes) {
    if (minutes < 1) minutes = 1; // 至少1分钟
    int newDuration = minutes * 60;
    if (m_workDuration != newDuration) {
        m_workDuration = newDuration;
        emit workDurationMinutesChanged();
        
        // 如果正在工作中，可以选择重置或者保持当前剩余时间
        // 这里选择如果处于工作状态且剩余时间大于新时长，则调整？
        // 简单策略：仅更新配置，下一次 startWork 生效。
        // 但如果用户想立即生效，可能会困惑。
        // 考虑到用户一般是在开始前或暂停时设置，我们可以重置。
        // 但为了不打断当前工作，我们只更新 m_workDuration。
        // 如果当前剩余时间大于新时间，也许应该截断？
        // 还是保持简单：下一次循环生效。
    }
}

void TimerEngine::startWork() {
    // 检查是否有休息记录
    if (m_breakStartTime.isValid()) {
        qint64 duration = m_breakStartTime.secsTo(QDateTime::currentDateTime());
        emit breakFinished((int)duration);
        m_breakStartTime = QDateTime(); // 重置无效
    }

    m_remainingSecs = m_workDuration;
    m_status = "工作中";
    emit statusChanged();
    emit timeUpdated();
    
    // 确保计时器运行
    if (!m_timer->isActive()) {
        m_timer->start();
    }
}

void TimerEngine::snooze() {
    m_remainingSecs = m_snoozeDuration;
    m_status = "稍后提醒";
    emit statusChanged();
    emit timeUpdated();
    
    if (!m_timer->isActive()) {
        m_timer->start();
    }
}

void TimerEngine::stop() {
    m_timer->stop();
    m_status = "已暂停";
    emit statusChanged();
}

void TimerEngine::togglePause() {
    if (m_timer->isActive()) {
        stop();
    } else {
        // 如果是暂停状态，则恢复
        if (m_status == "已暂停") {
            m_status = "工作中";
            emit statusChanged();
            m_timer->start();
        } else {
            // 其他状态（如休息中、准备就绪），默认开始新工作
            startWork();
        }
    }
}

void TimerEngine::onTick() {
    if (m_remainingSecs > 0) {
        m_remainingSecs--;
        emit timeUpdated();
    } else {
        // 倒计时结束
        m_timer->stop();
        m_status = "请休息";
        // 记录休息开始时间
        m_breakStartTime = QDateTime::currentDateTime();
        
        emit statusChanged();
        emit reminderTriggered();
    }
}
