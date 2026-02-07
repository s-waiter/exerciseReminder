#ifndef SCHEDULEMANAGER_H
#define SCHEDULEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QDateTime>
#include <QVariant>
#include <QVector>
#include "../utils/LunarCalendar.h"

struct ScheduleItem {
    QString id;
    QString title;
    int type; // 0: Work, 1: Life, 2: Anniversary, 3: Health
    QTime time;
    bool enabled;
    
    // Repeat Logic
    int repeatType; // 0: Once, 1: Daily, 2: Weekly, 3: Monthly, 4: Yearly, 5: Custom
    QVariantMap repeatRule; 
    
    // Anniversary / Time Perception Logic
    int calendarType; // 0: Gregorian, 1: Lunar
    QDate targetDate; // The reference date (e.g. Birthday, Exam Date). For Lunar, stores (Year, Month, Day).
    bool showTimeSince; // Display "X days since..."
    bool showCountdown; // Display "X days until..."
    bool dailyBroadcast; // Trigger reminder daily for countdown events
    bool autoSwitch; // Auto switch from Countdown to TimeSince after event passes

    int advanceDays; // 0 means no advance reminder
    bool isPrepared; // true means gift is ready, stop reminding

    // Runtime state
    QDateTime lastTriggered;

    static ScheduleItem fromMap(const QVariantMap& map);
    QVariantMap toMap() const;
    QString getFrequencyText() const;
    
    // Helper to get calculated display text
    QString getTimePerceptionText() const;
};

class ScheduleManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList schedules READ getSchedules NOTIFY schedulesChanged)

public:
    explicit ScheduleManager(QObject *parent = nullptr);
    static ScheduleManager& instance();

    Q_INVOKABLE void addSchedule(const QVariantMap& scheduleData);
    Q_INVOKABLE void updateSchedule(const QString& id, const QVariantMap& scheduleData);
    Q_INVOKABLE void removeSchedule(const QString& id);
    Q_INVOKABLE void snoozeReminder(const QString& id, int minutes);
    Q_INVOKABLE void markPrepared(const QString& id, bool prepared);

    QVariantList getSchedules() const;
    void checkSchedules(); // Called by TimerEngine

signals:
    void schedulesChanged();
    void reminderTriggered(const QString& title, int type, const QString& message, const QString& id, const QVariantMap& options);

private:
    void loadSchedules();
    void saveSchedules();
    bool isDue(const ScheduleItem& item, const QDateTime& current);

    QVector<ScheduleItem> m_schedules;
    QString m_dbPath;
};

#endif // SCHEDULEMANAGER_H
