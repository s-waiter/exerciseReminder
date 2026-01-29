#include "TimerEngine.h"
#include <QDebug>
#include <QSettings>
#include <QDate>
#include <QVariant>
#include <QLocale>

// 构造函数
TimerEngine::TimerEngine(QObject *parent) 
    : QObject(parent)
    , m_workDuration(45 * 60) // 默认工作时长初始化为 45 分钟 (单位: 秒)
    , m_remainingSecs(45 * 60)
    , m_currentSessionTotal(45 * 60)
{
    // 实例化 QTimer 对象
    // "this" 作为 parent，意味着当 TimerEngine 被销毁时，m_timer 也会自动被销毁。
    m_timer = new QTimer(this);
    
    // 设置定时器间隔为 1000 毫秒 (1秒)
    m_timer->setInterval(1000); 
    
    // 连接信号与槽：
    // 当定时器超时 (timeout) 时，调用本类的 onTick() 函数。
    // 这就是 Qt 的事件驱动编程模式。
    connect(m_timer, &QTimer::timeout, this, &TimerEngine::onTick);
    
    // 初始化状态
    m_status = "准备就绪";
    
    // 默认启动时直接开始工作计时
    startWork(); 
}

// -------------------------------------------------------------------------
// Getter 函数实现 (直接返回成员变量)
// -------------------------------------------------------------------------

int TimerEngine::remainingSeconds() const { return m_remainingSecs; }

QString TimerEngine::statusText() const { return m_status; }

int TimerEngine::workDurationMinutes() const {
    return m_workDuration / 60; // 秒转换为分钟
}

int TimerEngine::currentSessionTotalTime() const {
    return m_currentSessionTotal;
}

// 计算预计完成时间 (ETA)
QString TimerEngine::estimatedFinishTime() const {
    // 如果是暂停状态，无法计算 ETA
    if (m_status == "已暂停") return "--:--";
    
    // QDateTime::currentDateTime() 获取系统当前时间
    // addSecs() 加上剩余秒数，得到预计结束时间点
    // toString("HH:mm") 格式化为 "小时:分钟" 字符串
    return QDateTime::currentDateTime().addSecs(m_remainingSecs).toString("HH:mm");
}

// -------------------------------------------------------------------------
// Setter / Slots 实现
// -------------------------------------------------------------------------

void TimerEngine::setWorkDurationMinutes(int minutes) {
    if (minutes < 1) minutes = 1; // 边界检查：至少1分钟
    
    int newDuration = minutes * 60;
    
    // 只有当值真正改变时才执行操作 (避免死循环或不必要的信号)
    if (m_workDuration != newDuration) {
        m_workDuration = newDuration;
        
        // 发出通知信号，告诉 QML 值已经改变了
        emit workDurationMinutesChanged();
        
        // 注意：这里我们没有立即重置正在进行的倒计时。
        // 新的设置将在下一次 startWork() 时生效。
        // 这是一种常见的设计选择，避免打断用户当前的工作流。
    }
}

void TimerEngine::startWork() {
    // 检查是否有休息记录 (如果之前是在休息状态)
    if (m_breakStartTime.isValid()) {
        // 计算休息了多少秒
        qint64 duration = m_breakStartTime.secsTo(QDateTime::currentDateTime());
        emit breakFinished((int)duration);
        m_breakStartTime = QDateTime(); // 重置为无效时间
    }

    // 重置倒计时
    m_remainingSecs = m_workDuration;
    m_currentSessionTotal = m_workDuration; // 锁定本次会话的总时长 (用于进度条)
    
    // 发出信号通知前端更新
    emit currentSessionTotalTimeChanged();
    
    m_status = "工作中";
    emit statusChanged();
    emit timeUpdated();
    
    // 启动定时器 (如果还没启动)
    if (!m_timer->isActive()) {
        m_timer->start();
    }
}

// 贪睡功能：延迟 5 分钟提醒
void TimerEngine::snooze() {
    m_remainingSecs = m_snoozeDuration;
    m_currentSessionTotal = m_snoozeDuration; // 进度条分母设为5分钟
    emit currentSessionTotalTimeChanged();
    
    m_status = "稍后提醒";
    emit statusChanged();
    emit timeUpdated();
    
    if (!m_timer->isActive()) {
        m_timer->start();
    }
}

void TimerEngine::stop() {
    m_timer->stop(); // 停止硬件定时器
    m_status = "已暂停";
    emit statusChanged();
}

// 智能暂停/恢复切换
void TimerEngine::togglePause() {
    if (m_timer->isActive()) {
        // 如果正在运行，则暂停
        stop();
    } else {
        // 如果未运行
        if (m_status == "已暂停") {
            // 从暂停中恢复
            m_status = "工作中";
            emit statusChanged();
            m_timer->start();
        } else {
            // 如果是其他状态（如休息结束、准备就绪），则开启新一轮工作
            startWork();
        }
    }
}

// ========================================================================
// 数据统计相关实现
// ========================================================================

// 记录一次运动时长
void TimerEngine::recordExercise(int durationSeconds) {
    if (durationSeconds <= 0) return;

    QSettings settings("ExerciseReminder", "Stats");
    QDateTime now = QDateTime::currentDateTime();
    QString today = now.toString("yyyy-MM-dd");
    
    // 1. 更新每日总时长
    int current = settings.value(today, 0).toInt();
    settings.setValue(today, current + durationSeconds);
    
    // 2. 记录本次会话详情
    QString sessionKey = "Sessions/" + today;
    QVariantList sessions = settings.value(sessionKey).toList();
    
    QVariantMap session;
    // 计算开始时间
    QDateTime start = now.addSecs(-durationSeconds);
    session["start"] = start.toString("HH:mm");
    session["end"] = now.toString("HH:mm");
    session["duration"] = durationSeconds;
    
    sessions.append(session);
    settings.setValue(sessionKey, sessions);
    
    // 强制同步以确保写入磁盘
    settings.sync();
    
    qDebug() << "Recorded exercise:" << durationSeconds << "s. Today total:" << (current + durationSeconds);
}

int TimerEngine::getTodayExerciseSeconds() {
    QSettings settings("ExerciseReminder", "Stats");
    QString today = QDate::currentDate().toString("yyyy-MM-dd");
    return settings.value(today, 0).toInt();
}

QVariantList TimerEngine::getTodaySessions() {
    QSettings settings("ExerciseReminder", "Stats");
    QString todayKey = "Sessions/" + QDate::currentDate().toString("yyyy-MM-dd");
    return settings.value(todayKey).toList();
}

QVariantList TimerEngine::getWeeklyExerciseStats() {
    QSettings settings("ExerciseReminder", "Stats");
    QVariantList list;
    QDate today = QDate::currentDate();
    
    // 获取过去7天的数据 (包括今天)
    for (int i = 6; i >= 0; --i) {
        QDate date = today.addDays(-i);
        QString key = date.toString("yyyy-MM-dd");
        
        int seconds = settings.value(key, 0).toInt();
        
        QVariantMap map;
        map["date"] = date.toString("MM/dd");
        // 获取星期几的短名称 (如 "周一", "Mon")
        map["day"] = QLocale().dayName(date.dayOfWeek(), QLocale::ShortFormat);
        map["seconds"] = seconds;
        
        // 标记是否是今天，方便前端高亮
        map["isToday"] = (i == 0);
        
        list.append(map);
    }
    return list;
}

// 定时器回调函数 (每秒执行一次)
void TimerEngine::onTick() {
    if (m_remainingSecs > 0) {
        m_remainingSecs--;
        // 触发 timeUpdated 信号，QML 界面收到后会更新剩余时间和进度条
        emit timeUpdated();
    } else {
        // 倒计时结束
        m_timer->stop();
        m_status = "请休息";
        
        // 记录休息开始时间
        m_breakStartTime = QDateTime::currentDateTime();
        
        emit statusChanged();
        
        // 触发核心提醒信号 -> 将导致全屏窗口弹出
        emit reminderTriggered();
    }
}
