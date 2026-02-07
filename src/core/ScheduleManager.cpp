#include "ScheduleManager.h"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QUuid>
#include <QDebug>
#include "../utils/LunarCalendar.h"

ScheduleItem ScheduleItem::fromMap(const QVariantMap& map)
{
    ScheduleItem item;
    item.id = map.value("id").toString();
    if (item.id.isEmpty()) item.id = QUuid::createUuid().toString();
    item.title = map.value("title").toString();
    item.type = map.value("type", 0).toInt();
    item.time = map.value("time").toTime();
    item.enabled = map.value("enabled", true).toBool();
    item.repeatType = map.value("repeatType", 0).toInt();
    item.repeatRule = map.value("repeatRule").toMap();
    item.advanceDays = map.value("advanceDays", 0).toInt();
    item.isPrepared = map.value("isPrepared", false).toBool();
    item.lastTriggered = map.value("lastTriggered").toDateTime();

    // Time Perception
    item.calendarType = map.value("calendarType", 0).toInt();
    QString targetDateStr = map.value("targetDate").toString();
    if (!targetDateStr.isEmpty()) {
        item.targetDate = QDate::fromString(targetDateStr, Qt::ISODate);
    }
    item.showTimeSince = map.value("showTimeSince", false).toBool();
    item.showCountdown = map.value("showCountdown", false).toBool();
    item.dailyBroadcast = map.value("dailyBroadcast", false).toBool();
    item.autoSwitch = map.value("autoSwitch", false).toBool();

    return item;
}

QVariantMap ScheduleItem::toMap() const
{
    QVariantMap map;
    map["id"] = id;
    map["title"] = title;
    map["type"] = type;
    map["time"] = time;
    map["enabled"] = enabled;
    map["repeatType"] = repeatType;
    map["repeatRule"] = repeatRule;
    map["advanceDays"] = advanceDays;
    map["isPrepared"] = isPrepared;
    map["lastTriggered"] = lastTriggered;
    
    // Time Perception
    map["calendarType"] = calendarType;
    if (targetDate.isValid()) {
        map["targetDate"] = targetDate.toString(Qt::ISODate);
    }
    map["showTimeSince"] = showTimeSince;
    map["showCountdown"] = showCountdown;
    map["dailyBroadcast"] = dailyBroadcast;
    map["autoSwitch"] = autoSwitch;

    // Helper for UI
    map["freqText"] = getFrequencyText();
    map["timePerceptionText"] = getTimePerceptionText();
    return map;
}

QString ScheduleItem::getFrequencyText() const
{
    if (repeatType == 0) {
        if (calendarType == 1 && targetDate.isValid()) {
            return "农历 " + LunarCalendar::getLunarDateString(targetDate) + " (一次性)"; // Wait, targetDate for Lunar is raw YMD?
            // Actually if calendarType=1, targetDate is stored as 1993-08-09.
            // LunarCalendar::getLunarDateString takes Solar Date.
            // We want to format the Lunar Date: "农历 1993年八月初九"
            // LunarDate struct to string.
            // We can construct a LunarDate.
            return QString("农历 %1年%2%3").arg(targetDate.year())
                   .arg(LunarCalendar::getLunarMonthString(targetDate.month()))
                   .arg(LunarCalendar::getLunarDayString(targetDate.day()));
        }
        return "一次性";
    }
    if (repeatType == 1) return "每天";
    if (repeatType == 2) {
        // Weekly
        QVariantList days = repeatRule.value("days").toList();
        QStringList dayNames;
        QStringList cnDays = {"", "周一", "周二", "周三", "周四", "周五", "周六", "周日"};
        for (const QVariant& d : days) {
            int day = d.toInt();
            if (day >= 1 && day <= 7) dayNames << cnDays[day];
        }
        return "每周 " + dayNames.join("、");
    }
    if (repeatType == 3) {
        int day = repeatRule.value("day").toInt();
        if (day == -1) return "每月最后一天";
        return QString("每月 %1 日").arg(day);
    }
    if (repeatType == 4) {
        // Yearly
        if (calendarType == 1) {
            // Lunar Yearly
            int m = repeatRule.value("month").toInt();
            int d = repeatRule.value("day").toInt();
            QString text = QString("每年农历 %1%2").arg(LunarCalendar::getLunarMonthString(m)).arg(LunarCalendar::getLunarDayString(d));
            if (advanceDays > 0) text += QString(" (提前%1天)").arg(advanceDays);
            return text;
        }
        
        int m = repeatRule.value("month").toInt();
        int d = repeatRule.value("day").toInt();
        QString text = QString("每年 %1月%2日").arg(m).arg(d);
        if (advanceDays > 0) text += QString(" (提前%1天)").arg(advanceDays);
        return text;
    }
    if (repeatType == 5) {
        int interval = repeatRule.value("interval").toInt();
        QString unit = repeatRule.value("unit").toString();
        QString uStr = "天";
        if (unit == "week") uStr = "周";
        else if (unit == "hour") uStr = "小时";
        else if (unit == "minute") uStr = "分钟";
        
        QString suffix = "";
        if (unit == "week") {
            QDate start = QDate::fromString(repeatRule.value("startDate").toString(), Qt::ISODate);
            if (start.isValid()) {
                QStringList cnDays = {"", "周一", "周二", "周三", "周四", "周五", "周六", "周日"};
                suffix = " " + cnDays[start.dayOfWeek()];
            }
        }
        return QString("每 %1 %2%3").arg(interval).arg(uStr).arg(suffix);
    }
    return "";
}

QString ScheduleItem::getTimePerceptionText() const {
    QStringList parts;

    // 1. Next Reminder Logic (High Frequency OR Daily/Weekly)
    QString nextReminderStr;
    
    // High Frequency (Custom Hour/Minute)
    if (enabled && repeatType == 5) {
        QString unit = repeatRule.value("unit").toString();
        if (unit == "hour" || unit == "minute") {
            QDate sDate = QDate::fromString(repeatRule.value("startDate").toString(), Qt::ISODate);
            if (sDate.isValid()) {
                QDateTime start(sDate, time);
                int interval = repeatRule.value("interval").toInt();
                QDateTime current = QDateTime::currentDateTime();
                
                if (start.isValid()) {
                    qint64 intervalSecs = (unit == "hour") ? interval * 3600 : interval * 60;
                    if (intervalSecs <= 0) intervalSecs = 3600; 
                    
                    qint64 secsDiff = start.secsTo(current);
                    
                    QDateTime nextRun;
                    if (secsDiff < 0) {
                        nextRun = start; 
                    } else {
                        qint64 cycles = secsDiff / intervalSecs;
                        nextRun = start.addSecs((cycles + 1) * intervalSecs);
                    }
                    
                    qint64 secsToNext = current.secsTo(nextRun);
                    if (secsToNext < 0) secsToNext = 0;
                    
                    int h = secsToNext / 3600;
                    int m = (secsToNext % 3600) / 60;
                    
                    QString remainStr;
                    if (h > 0) remainStr += QString("%1小时").arg(h);
                    remainStr += QString("%1分").arg(m);
                    
                    nextReminderStr = QString("下次:%1(还有%2)").arg(nextRun.toString("HH:mm")).arg(remainStr);
                }
            }
        }
    }
    // Daily/Weekly
    else if (enabled && (repeatType == 1 || repeatType == 2)) {
        QDateTime current = QDateTime::currentDateTime();
        QDateTime nextRun;
        
        if (repeatType == 1) { // Daily
            QDateTime todayRun(current.date(), time);
            if (current < todayRun) {
                nextRun = todayRun;
            } else {
                nextRun = todayRun.addDays(1);
            }
        } else { // Weekly
            QDateTime todayRun(current.date(), time);
            QVariantList days = repeatRule.value("days").toList();
            nextRun = QDateTime(); 
            
            int currentDay = current.date().dayOfWeek();
            bool todayIsScheduled = false;
            for(const auto& d : days) if(d.toInt() == currentDay) todayIsScheduled = true;
            
            if (todayIsScheduled && current < todayRun) {
                nextRun = todayRun;
            } else {
                for (int i = 1; i <= 7; ++i) {
                    int nextDay = currentDay + i;
                    if (nextDay > 7) nextDay -= 7;
                    bool isScheduled = false;
                    for(const auto& d : days) if(d.toInt() == nextDay) isScheduled = true;
                    if (isScheduled) {
                        nextRun = QDateTime(current.date().addDays(i), time);
                        break;
                    }
                }
            }
        }
        
        if (nextRun.isValid()) {
             qint64 secsToNext = current.secsTo(nextRun);
             if (secsToNext < 0) secsToNext = 0;
             
             if (secsToNext > 86400) {
                 int d = secsToNext / 86400;
                 nextReminderStr = QString("下次:%1(还有%2天)").arg(nextRun.toString("MM-dd HH:mm")).arg(d);
             } else {
                 int h = secsToNext / 3600;
                 int m = (secsToNext % 3600) / 60;
                 QString remainStr;
                 if (h > 0) remainStr += QString("%1小时").arg(h);
                 remainStr += QString("%1分").arg(m);
                 nextReminderStr = QString("下次:%1(还有%2)").arg(nextRun.toString("HH:mm")).arg(remainStr);
             }
        }
    }

    if (!nextReminderStr.isEmpty()) {
        parts << nextReminderStr;
    }

    // 2. Time Since (Past) Logic
    if (targetDate.isValid() && showTimeSince) {
        QDate today = QDate::currentDate();
        QDate startDate;
        if (calendarType == 1) {
            startDate = LunarCalendar::lunarToSolar(targetDate.year(), targetDate.month(), targetDate.day());
        } else {
            startDate = targetDate;
        }
        
        qint64 days = startDate.daysTo(today);
        if (days >= 0) {
            QString text = QString("已累计%1天").arg(days);
            
            int y = 0, m = 0, d = 0;
            QDate temp = startDate;
            while (temp.addYears(1) <= today) { temp = temp.addYears(1); y++; }
            while (temp.addMonths(1) <= today) { temp = temp.addMonths(1); m++; }
            d = temp.daysTo(today);
            
            QString suffix;
            if (y > 0) suffix += QString("%1年").arg(y);
            if (m > 0) suffix += QString("%1个月").arg(m);
            if (d > 0) suffix += QString("%1天").arg(d);
            
            if (!suffix.isEmpty()) {
                text += QString("(%1)").arg(suffix);
            }
            parts << text;
        }
    }

    // 3. Countdown (Future) Logic
    if (targetDate.isValid() && showCountdown) {
        QDate today = QDate::currentDate();
        QDate nextDate;
        
        if (repeatType == 0) { // Once
            if (calendarType == 1) {
                nextDate = LunarCalendar::lunarToSolar(targetDate.year(), targetDate.month(), targetDate.day());
            } else {
                nextDate = targetDate;
            }
        } else if (repeatType == 4) { // Yearly
            int targetM = repeatRule.value("month").toInt();
            int targetD = repeatRule.value("day").toInt();

            if (calendarType == 1) {
                LunarDate lunarToday = LunarCalendar::solarToLunar(today);
                QDate thisYearSolar = LunarCalendar::lunarToSolar(lunarToday.year, targetM, targetD);
                if (today <= thisYearSolar) nextDate = thisYearSolar;
                else nextDate = LunarCalendar::lunarToSolar(lunarToday.year + 1, targetM, targetD);
            } else {
                QDate thisYear(today.year(), targetM, targetD);
                if (!thisYear.isValid() && targetM==2 && targetD==29) thisYear = QDate(today.year(), 2, 28);
                
                if (today <= thisYear) nextDate = thisYear;
                else {
                    nextDate = QDate(today.year() + 1, targetM, targetD);
                    if (!nextDate.isValid() && targetM==2 && targetD==29) nextDate = QDate(today.year()+1, 2, 28);
                }
            }
        }
        
        if (nextDate.isValid()) {
            qint64 days = today.daysTo(nextDate);
            if (days >= 0) {
                QString text = QString("还有%1天").arg(days);
                if (days == 0) text = "今天";
                
                if (days > 30) {
                    int y = 0, m = 0, d = 0;
                    QDate temp = today;
                    while (temp.addYears(1) <= nextDate) { temp = temp.addYears(1); y++; }
                    while (temp.addMonths(1) <= nextDate) { temp = temp.addMonths(1); m++; }
                    d = temp.daysTo(nextDate);
                    
                    QString suffix;
                    if (y > 0) suffix += QString("%1年").arg(y);
                    if (m > 0) suffix += QString("%1个月").arg(m);
                    if (d > 0) suffix += QString("%1天").arg(d);
                    
                    if (!suffix.isEmpty()) text += QString("(%1)").arg(suffix);
                }
                parts << text;
            }
        }
    }

    return parts.join("\n");
}

ScheduleManager::ScheduleManager(QObject *parent) : QObject(parent)
{
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dataDir);
    if (!dir.exists()) dir.mkpath(".");
    m_dbPath = dataDir + "/schedules.json";
    loadSchedules();
}

ScheduleManager& ScheduleManager::instance()
{
    static ScheduleManager instance;
    return instance;
}

void ScheduleManager::addSchedule(const QVariantMap& scheduleData)
{
    ScheduleItem item = ScheduleItem::fromMap(scheduleData);
    m_schedules.append(item);
    saveSchedules();
    emit schedulesChanged();
}

void ScheduleManager::updateSchedule(const QString& id, const QVariantMap& scheduleData)
{
    for (int i = 0; i < m_schedules.size(); ++i) {
        if (m_schedules[i].id == id) {
            m_schedules[i] = ScheduleItem::fromMap(scheduleData);
            // Preserve ID if not in data (though fromMap handles it)
            if (m_schedules[i].id.isEmpty()) m_schedules[i].id = id;
            saveSchedules();
            emit schedulesChanged();
            return;
        }
    }
}

void ScheduleManager::removeSchedule(const QString& id)
{
    for (int i = 0; i < m_schedules.size(); ++i) {
        if (m_schedules[i].id == id) {
            m_schedules.removeAt(i);
            saveSchedules();
            emit schedulesChanged();
            return;
        }
    }
}

void ScheduleManager::snoozeReminder(const QString& id, int minutes)
{
    QString title = "稍后提醒";
    int type = 0;
    
    // Try to find original to copy details
    for (const auto& item : m_schedules) {
        if (item.id == id) {
            title = item.title + " (延后)";
            type = item.type;
            break;
        }
    }
    
    QDateTime current = QDateTime::currentDateTime();
    QDateTime snoozeTime = current.addSecs(minutes * 60);
    
    QVariantMap newSched;
    newSched["title"] = title;
    newSched["type"] = type;
    newSched["time"] = snoozeTime.time();
    newSched["enabled"] = true;
    newSched["repeatType"] = 0; // Once
    
    QVariantMap rule;
    rule["date"] = snoozeTime.date().toString(Qt::ISODate);
    newSched["repeatRule"] = rule;
    
    addSchedule(newSched);
}

void ScheduleManager::markPrepared(const QString& id, bool prepared)
{
    for (int i = 0; i < m_schedules.size(); ++i) {
        if (m_schedules[i].id == id) {
            m_schedules[i].isPrepared = prepared;
            saveSchedules();
            emit schedulesChanged();
            return;
        }
    }
}

QVariantList ScheduleManager::getSchedules() const
{
    QVariantList list;
    for (const auto& item : m_schedules) {
        list.append(item.toMap());
    }
    return list;
}

void ScheduleManager::checkSchedules()
{
    QDateTime current = QDateTime::currentDateTime();
    bool changed = false;

    for (auto& item : m_schedules) {
        // Auto-switch logic for Countdown -> TimeSince
        // Only for "Once" events (like Gaokao)
        // We check this even if disabled, so that past events correctly switch to "Time Since" display
        if (item.showCountdown && item.autoSwitch && item.repeatType == 0) {
            QDate eventDate;
            if (item.calendarType == 1) {
                eventDate = LunarCalendar::lunarToSolar(item.targetDate.year(), item.targetDate.month(), item.targetDate.day());
            } else {
                eventDate = item.targetDate;
            }
            
            // If eventDate is in the past (yesterday or earlier)
            if (eventDate < current.date()) {
                item.showCountdown = false;
                item.showTimeSince = true;
                changed = true;
                qDebug() << "Auto-switched schedule" << item.title << "to TimeSince mode.";
            }
        }

        if (!item.enabled) continue;

        // Check if we should trigger
        // We trigger if it's due AND (it hasn't been triggered today/this minute OR it's a new occurrence)
        // For simplicity, we check if lastTriggered is not within the same minute
        // AND if isDue is true.
        
        bool isMainDue = isDue(item, current);
        bool due = isMainDue;
        
        // REQ-015: Daily Broadcast for Countdown
        // If not due (not the main event day), but dailyBroadcast is ON and it's a new day
        if (!due && item.showCountdown && item.dailyBroadcast) {
            // Check if triggered today
            if (item.lastTriggered.isValid() && item.lastTriggered.date() == current.date()) {
                // Already triggered today
            } else {
                // Not triggered today. But at what time?
                // Use the schedule time.
                if (current.time().hour() == item.time.hour() && current.time().minute() == item.time.minute()) {
                    due = true;
                }
            }
        }

        if (due) {
            // Check if already triggered recently (within 60 seconds)
            if (item.lastTriggered.isValid() && item.lastTriggered.secsTo(current) < 60) {
                continue;
            }

            // Trigger!
            QVariantMap options;
            
            // Pass the Time Perception text to the reminder
            QString perceptionText = item.getTimePerceptionText();
            if (!perceptionText.isEmpty()) {
                options["perceptionText"] = perceptionText;
            }
            
            emit reminderTriggered(item.title, item.type, "时间到了！", item.id, options);
            item.lastTriggered = current;
            changed = true;
            
            // Auto-disable "Once" schedules after triggering
            // ONLY if it is the Main Event (isMainDue), NOT if it is a Daily Broadcast or Advance Reminder
            // Note: isDue for Type 0 currently only returns true for the exact date.
            if (item.repeatType == 0 && isMainDue) {
                item.enabled = false;
            }
            
            // If it is the actual day of anniversary (not advance), reset isPrepared for next year
            if (item.repeatType == 4) {
                 // Check if it is the main event day
                 bool isMainDay = false;
                 if (item.calendarType == 1) {
                     LunarDate lunarToday = LunarCalendar::solarToLunar(current.date());
                     int m = item.repeatRule.value("month").toInt();
                     int d = item.repeatRule.value("day").toInt();
                     if (lunarToday.month == m && lunarToday.day == d) isMainDay = true;
                 } else {
                     int m = item.repeatRule.value("month").toInt();
                     int d = item.repeatRule.value("day").toInt();
                     if (current.date().month() == m && current.date().day() == d) isMainDay = true;
                 }
                 
                 if (isMainDay) {
                     if (item.isPrepared) {
                         item.isPrepared = false; // Reset for next year
                     }
                 }
            }
        }
        
        // Daily Countdown Reminder Logic (REQ-015)
        // If showCountdown is true, we force a daily check if enabled
        // Implementation: If showCountdown is true, we trigger every day at the specific time
        // provided the event hasn't happened yet.
    }

    if (changed) {
        saveSchedules();
        emit schedulesChanged();
    }
}

bool ScheduleManager::isDue(const ScheduleItem& item, const QDateTime& current)
{
    // Check if Custom Time Interval (Hour/Minute)
    bool isCustomTimeInterval = false;
    if (item.repeatType == 5) {
        QString unit = item.repeatRule.value("unit").toString();
        if (unit == "hour" || unit == "minute") {
            isCustomTimeInterval = true;
        }
    }

    // 1. Check Time match (Hour/Minute)
    // We allow a 1-minute window
    // For Custom Time Interval, we skip this check and handle it inside case 5
    if (!isCustomTimeInterval) {
        if (item.time.hour() != current.time().hour() || item.time.minute() != current.time().minute()) {
            return false;
        }
    }

    QDate today = current.date();

    switch (item.repeatType) {
    case 0: // Once
    {
        // Support date-specific "Once"
        // If calendarType == 1 (Lunar), convert targetDate to Solar and check
        if (item.calendarType == 1 && item.targetDate.isValid()) {
             QDate solarTarget = LunarCalendar::lunarToSolar(item.targetDate.year(), item.targetDate.month(), item.targetDate.day());
             if (solarTarget != today) return false;
             return true;
        }
        
        QString dateStr = item.repeatRule.value("date").toString();
        // If targetDate is set (REQ-015), use it as the date?
        // Usually `repeatRule["date"]` is used for snooze/custom.
        // Let's unify: If targetDate is set, use it.
        if (item.targetDate.isValid()) {
            if (item.targetDate != today) return false;
            return true;
        }

        if (!dateStr.isEmpty()) {
             QDate targetDate = QDate::fromString(dateStr, Qt::ISODate);
             if (targetDate.isValid() && targetDate != today) return false;
        }
        return true; 
    } 
        
    case 1: // Daily
        return true;
        
    case 2: // Weekly
    {
        QVariantList days = item.repeatRule.value("days").toList();
        int currentDay = today.dayOfWeek(); // 1-7
        for (const QVariant& d : days) {
            if (d.toInt() == currentDay) return true;
        }
        return false;
    }
    
    case 3: // Monthly
    {
        int targetDay = item.repeatRule.value("day").toInt();
        if (targetDay == -1) {
            // Last day of month
            return today.day() == today.daysInMonth();
        }
        // Lunar Monthly? Not requested but could support.
        // Assuming Gregorian for now unless calendarType is checked.
        if (item.calendarType == 1) {
             LunarDate lunar = LunarCalendar::solarToLunar(today);
             return lunar.day == targetDay;
        }
        return today.day() == targetDay;
    }
    
    case 4: // Yearly (Anniversary)
    {
        int m = item.repeatRule.value("month").toInt();
        int d = item.repeatRule.value("day").toInt();
        
        if (item.calendarType == 1) {
            // Lunar Anniversary
            LunarDate lunar = LunarCalendar::solarToLunar(today);
            if (lunar.month == m && lunar.day == d) return true;
            
            // Advance
            if (item.advanceDays > 0 && !item.isPrepared) {
                // Next Lunar Date
                // We need to find the Solar Date of the Next Lunar Anniversary
                // Try this year's lunar occurrence
                QDate nextSolar = LunarCalendar::lunarToSolar(lunar.year, m, d);
                // If it's already passed or is today, try next year
                if (nextSolar <= today) {
                    nextSolar = LunarCalendar::lunarToSolar(lunar.year + 1, m, d);
                }
                
                qint64 daysTo = today.daysTo(nextSolar);
                if (daysTo > 0 && daysTo <= item.advanceDays) return true;
            }
            return false;
        }
        
        // Gregorian
        // Check actual day
        if (today.month() == m && today.day() == d) {
            return true; // Always remind on the day
        }
        
        // Check advance
        if (item.advanceDays > 0 && !item.isPrepared) {
            QDate eventDate(today.year(), m, d);
            if (!eventDate.isValid()) {
                 // Handle Feb 29
                 if (m == 2 && d == 29) eventDate = QDate(today.year(), 3, 1); 
            }
            
            // If event is in the past this year, look at next year
            if (eventDate < today) {
                eventDate = QDate(today.year() + 1, m, d);
                if (!eventDate.isValid() && m == 2 && d == 29) eventDate = QDate(today.year() + 1, 3, 1);
            }
            
            qint64 daysTo = today.daysTo(eventDate);
            if (daysTo > 0 && daysTo <= item.advanceDays) {
                return true;
            }
        }
        return false;
    }
    
    case 5: // Custom
    {
        int interval = item.repeatRule.value("interval").toInt();
        if (interval <= 0) interval = 1;

        QString unit = item.repeatRule.value("unit").toString();
        QDate startDate = QDate::fromString(item.repeatRule.value("startDate").toString(), Qt::ISODate);
        
        if (!startDate.isValid()) return false;
        
        if (unit == "day") {
            qint64 daysDiff = startDate.daysTo(today);
            return (daysDiff >= 0 && daysDiff % interval == 0);
        } else if (unit == "week") {
            if (today.dayOfWeek() != startDate.dayOfWeek()) return false;
            
            qint64 daysDiff = startDate.daysTo(today);
            qint64 weeksDiff = daysDiff / 7;
            return (daysDiff >= 0 && weeksDiff % interval == 0);
        } else if (unit == "hour") {
            // Combine startDate with item.time to get startDateTime
            QDateTime startDateTime(startDate, item.time);
            if (!startDateTime.isValid()) return false;
            if (current < startDateTime) return false;
            
            qint64 secsDiff = startDateTime.secsTo(current);
            qint64 hoursDiff = secsDiff / 3600;
            
            // Trigger if minutes match AND hours match interval
            if (current.time().minute() != item.time.minute()) return false;
            
            return (hoursDiff % interval == 0);
        } else if (unit == "minute") {
            QDateTime startDateTime(startDate, item.time);
            if (!startDateTime.isValid()) return false;
            if (current < startDateTime) return false;
            
            qint64 secsDiff = startDateTime.secsTo(current);
            qint64 minsDiff = secsDiff / 60;
            
            // Trigger if minutes match interval
            return (minsDiff % interval == 0);
        }
        return false;
    }
    }

    return false;
}

void ScheduleManager::loadSchedules()
{
    QFile file(m_dbPath);
    if (!file.open(QIODevice::ReadOnly)) return;
    
    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    QJsonArray array = doc.array();
    
    m_schedules.clear();
    for (const auto& val : array) {
        m_schedules.append(ScheduleItem::fromMap(val.toObject().toVariantMap()));
    }
    file.close();
}

void ScheduleManager::saveSchedules()
{
    QJsonArray array;
    for (const auto& item : m_schedules) {
        array.append(QJsonObject::fromVariantMap(item.toMap()));
    }
    
    QFile file(m_dbPath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(array).toJson());
        file.close();
    }
}
