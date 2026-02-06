#include "ScheduleManager.h"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QUuid>
#include <QDebug>

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
    
    // Helper for UI
    map["freqText"] = getFrequencyText();
    return map;
}

QString ScheduleItem::getFrequencyText() const
{
    if (repeatType == 0) return "一次性";
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
        int m = repeatRule.value("month").toInt();
        int d = repeatRule.value("day").toInt();
        QString text = QString("每年 %1月%2日").arg(m).arg(d);
        if (advanceDays > 0) text += QString(" (提前%1天)").arg(advanceDays);
        return text;
    }
    if (repeatType == 5) {
        int interval = repeatRule.value("interval").toInt();
        QString unit = repeatRule.value("unit").toString();
        QString uStr = (unit == "week") ? "周" : "天";
        
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
        if (!item.enabled) continue;

        // Check if we should trigger
        // We trigger if it's due AND (it hasn't been triggered today/this minute OR it's a new occurrence)
        // For simplicity, we check if lastTriggered is not within the same minute
        // AND if isDue is true.
        
        if (isDue(item, current)) {
            // Check if already triggered recently (within 60 seconds)
            if (item.lastTriggered.isValid() && item.lastTriggered.secsTo(current) < 60) {
                continue;
            }

            // Special handling for Anniversary Advance
            // If it is an advance reminder, we trigger it.
            // But we need to distinguish between "Advance Reminder" and "Day Of Event Reminder"
            
            // Logic:
            // 1. Check if it's the actual event time.
            // 2. Check if it's an advance reminder time.
            
            // For now, isDue returns true for both.
            // Trigger!
            emit reminderTriggered(item.title, QString::number(item.type));
            item.lastTriggered = current;
            changed = true;
            
            // If it is the actual day of anniversary (not advance), reset isPrepared for next year
            if (item.repeatType == 4) {
                 int m = item.repeatRule.value("month").toInt();
                 int d = item.repeatRule.value("day").toInt();
                 if (current.date().month() == m && current.date().day() == d) {
                     if (item.isPrepared) {
                         item.isPrepared = false; // Reset for next year
                     }
                 }
            }
        }
    }

    if (changed) saveSchedules();
}

bool ScheduleManager::isDue(const ScheduleItem& item, const QDateTime& current)
{
    // 1. Check Time match (Hour/Minute)
    // We allow a 1-minute window
    if (item.time.hour() != current.time().hour() || item.time.minute() != current.time().minute()) {
        return false;
    }

    QDate today = current.date();

    switch (item.repeatType) {
    case 0: // Once
        // For "Once", we assume the date was stored? Or just today?
        // Usually "Once" needs a specific date. 
        // For this simple implementation, let's say "Once" disables itself after trigger.
        // But we lack a "date" field in ScheduleItem for "Once". 
        // Let's assume "Once" means "Today only" or "Next occurrence".
        // If it's enabled and time matches, trigger and disable.
        return true; 
        
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
        return today.day() == targetDay;
    }
    
    case 4: // Yearly (Anniversary)
    {
        int m = item.repeatRule.value("month").toInt();
        int d = item.repeatRule.value("day").toInt();
        
        // Check actual day
        if (today.month() == m && today.day() == d) {
            return true; // Always remind on the day
        }
        
        // Check advance
        if (item.advanceDays > 0 && !item.isPrepared) {
            QDate eventDate(today.year(), m, d);
            if (!eventDate.isValid()) {
                 // Handle Feb 29
                 if (m == 2 && d == 29) eventDate = QDate(today.year(), 3, 1); // Or Feb 28?
            }
            
            // If event is in the past this year, look at next year? 
            // Actually advance reminder implies event is in future.
            
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
        if (interval <= 0) interval = 1; // Safety fallback

        QString unit = item.repeatRule.value("unit").toString();
        QDate startDate = QDate::fromString(item.repeatRule.value("startDate").toString(), Qt::ISODate);
        
        if (!startDate.isValid()) return false;
        
        if (unit == "day") {
            qint64 daysDiff = startDate.daysTo(today);
            return (daysDiff >= 0 && daysDiff % interval == 0);
        } else if (unit == "week") {
            // Must be same day of week
            if (today.dayOfWeek() != startDate.dayOfWeek()) return false;
            
            qint64 daysDiff = startDate.daysTo(today);
            qint64 weeksDiff = daysDiff / 7;
            return (daysDiff >= 0 && weeksDiff % interval == 0);
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
