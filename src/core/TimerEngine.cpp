#include "TimerEngine.h"
#include <QDebug>

TimerEngine::TimerEngine(QObject *parent) : QObject(parent), m_remainingSecs(m_workDuration)
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

void TimerEngine::startWork() {
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

void TimerEngine::onTick() {
    if (m_remainingSecs > 0) {
        m_remainingSecs--;
        emit timeUpdated();
    } else {
        // 倒计时结束
        m_timer->stop();
        m_status = "请休息";
        emit statusChanged();
        emit reminderTriggered();
    }
}
