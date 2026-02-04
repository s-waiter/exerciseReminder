#include "ActivityLogger.h"
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QSqlError>
#include <QJsonDocument>
#include <QJsonObject>

ActivityLogger::ActivityLogger(TimerEngine* engine, QObject *parent)
    : QObject(parent), m_engine(engine), m_currentState(TimerEngine::State_Offline)
{
    initDatabase();

    if (m_engine) {
        connect(m_engine, &TimerEngine::activityStateChanged, this, &ActivityLogger::onActivityStateChanged);
        // 连接手动记录信号
        connect(m_engine, &TimerEngine::exerciseRecorded, this, &ActivityLogger::onManualExerciseRecorded);
        
        // Initialize with current engine state
        m_currentState = m_engine->currentActivityState();
        m_currentStartTime = QDateTime::currentDateTime();
        
        // If engine is already running (e.g. started before Logger), log it.
        // But usually Logger is created at startup.
        startNewSession(m_currentState);
    }
}

ActivityLogger::~ActivityLogger() {
    closeCurrentSession();
    if (m_db.isOpen()) {
        m_db.close();
    }
}

void ActivityLogger::initDatabase() {
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dataDir);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    QString dbPath = dir.filePath("activity_log.db");
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qCritical() << "Error opening database:" << m_db.lastError();
        return;
    }

    QSqlQuery query;
    // Create table if not exists
    // id, state (text), start_time (int timestamp), end_time (int timestamp), duration (int seconds)
    QString createTable = R"(
        CREATE TABLE IF NOT EXISTS activity_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            state TEXT,
            start_time INTEGER,
            end_time INTEGER,
            duration INTEGER
        )
    )";

    if (!query.exec(createTable)) {
        qCritical() << "Error creating table:" << query.lastError();
    } else {
        m_dbInitialized = true;
        
        // Check and add new columns if they don't exist (Migration)
        // content TEXT, work_type INTEGER
        // SQLite doesn't support IF NOT EXISTS for ADD COLUMN, so we just try and ignore error
        // or check pragma, but try-catch is simpler here since we just want to ensure they exist.
        
        query.exec("ALTER TABLE activity_log ADD COLUMN content TEXT");
        query.exec("ALTER TABLE activity_log ADD COLUMN work_type INTEGER DEFAULT 0");
    }

    // Crash Recovery: Close any sessions that have 0 duration (orphaned by crash)
    // We set end_time = start_time + 60 (1 min) to gracefully close them
    // Only affect rows where end_time is 0 or NULL (if schema allows NULL, but we use 0)
    QSqlQuery cleanupQuery;
    cleanupQuery.exec("UPDATE activity_log SET end_time = start_time + 60, duration = 60 WHERE (end_time = 0 OR end_time IS NULL) AND start_time > 0");
}

void ActivityLogger::onActivityStateChanged(TimerEngine::ActivityState newState) {
    if (newState == m_currentState) return;

    closeCurrentSession();
    startNewSession(newState);
}

void ActivityLogger::onManualExerciseRecorded(int durationSeconds) {
    if (!m_dbInitialized || durationSeconds <= 0) return;

    // 智能防重复逻辑：
    // 如果当前系统状态已经是 Rest，并且当前会话持续时间与记录的时间相近，
    // 我们倾向于认为这是自动记录已经覆盖了的情况，或者是用户在 Rest 模式下手动点击完成。
    // 但是，用户反馈明确指出数据丢失，说明之前的状态很可能不是 Rest (例如是 Pause)。
    // 因此，我们的策略是：
    // 1. 只要收到这个信号，就强制插入一条 Rest 记录。
    // 2. 插入的记录时间段为 [Now - Duration, Now]。
    // 3. 这样即使原先是 Pause 状态，现在也会有一条重叠的 Rest 记录，确保统计数据包含这段运动。
    
    // 唯一需要避免的是：如果我们确实在 Rest 模式下，且 ActivityLogger 稍后会(在 startWork 时)自动插入一条
    // 几乎完全一样的记录，那样会导致双倍统计。
    
    // 检查：如果当前是 Rest 状态，我们做一个标记或者调整当前会话？
    // 实际上，当用户点击“完成运动”时，OverlayWindow 会调用 recordExercise。
    // 紧接着 (或几秒后) 会调用 startWork，这会触发 onActivityStateChanged(Focus)，
    // 从而导致当前 Rest 会话被 closeCurrentSession() 写入数据库。
    
    // 假如用户在 Rest 模式下待了 5 分钟，点击完成。
    // recordExercise(300) -> onManualExerciseRecorded(300).
    // 如果我们在这里插入一条 300s 的记录。
    // 然后 startWork -> closeCurrentSession (Rest, 300s).
    // 结果：数据库里有两条 300s 的 Rest 记录。统计变 600s。这是错误的。
    
    if (m_currentState == TimerEngine::State_Rest) {
        qDebug() << "Manual exercise recorded while in Rest state. Trusting auto-logger to handle this session.";
        return; 
    }

    // 如果当前不是 Rest (例如是 Pause, Offline, Focus 等)，说明用户在非 Rest 状态下完成了运动。
    // 这种情况通常发生在用户在工作状态下手动触发运动，或者系统状态尚未切换。
    // 为了避免"Ongoing Session"覆盖这条手动记录（导致显示为蓝色覆盖绿色），我们需要截断当前会话。
    
    QDateTime now = QDateTime::currentDateTime();
    QDateTime exerciseStartTime = now.addSecs(-durationSeconds);
    
    // 1. 截断当前会话 (Ending at exerciseStartTime)
    // 如果 exerciseStartTime 比 m_currentStartTime 还早，说明整个当前会话都被覆盖了，
    // closeCurrentSession 会计算出负数或0，我们需要处理这种情况。
    QDateTime splitTime = exerciseStartTime;
    if (splitTime < m_currentStartTime) {
        splitTime = m_currentStartTime; // 至少保证不倒流
    }
    
    closeCurrentSession(splitTime);
    
    // 2. 插入手动记录 (Rest)
    QSqlQuery query;
    query.prepare("INSERT INTO activity_log (state, start_time, end_time, duration) VALUES (?, ?, ?, ?)");
    query.addBindValue("Rest"); // 强制标记为 Rest
    query.addBindValue(exerciseStartTime.toSecsSinceEpoch());
    query.addBindValue(now.toSecsSinceEpoch());
    query.addBindValue(durationSeconds);

    if (!query.exec()) {
        qWarning() << "Failed to insert manual exercise record:" << query.lastError();
    } else {
        qDebug() << "Inserted manual exercise record (compensating for non-Rest state):" << durationSeconds << "s";
    }
    
    // 3. 重新开始当前状态的会话 (Starting from now)
    // 这样就形成了一个缺口，缺口处被 Rest 填补
    startNewSession(m_currentState);
}

void ActivityLogger::closeCurrentSession(const QDateTime& customEndTime) {
    if (!m_dbInitialized) return;
    
    // If no active session ID, nothing to update
    if (m_currentId == -1) return;

    QDateTime endTime = customEndTime.isValid() ? customEndTime : QDateTime::currentDateTime();
    
    // 如果结束时间早于开始时间，直接忽略 (无效会话)
    if (endTime < m_currentStartTime) {
        qDebug() << "Ignoring invalid session duration (end < start):" << stateToString(m_currentState);
        // Delete the invalid row? Or just leave it as orphaned?
        // Let's delete it to keep DB clean
        QSqlQuery delQuery;
        delQuery.prepare("DELETE FROM activity_log WHERE id = ?");
        delQuery.addBindValue(m_currentId);
        delQuery.exec();
        m_currentId = -1;
        return;
    }
    
    qint64 duration = m_currentStartTime.secsTo(endTime);

    QSqlQuery query;
    query.prepare("UPDATE activity_log SET end_time = ?, duration = ? WHERE id = ?");
    query.addBindValue(endTime.toSecsSinceEpoch());
    query.addBindValue(duration);
    query.addBindValue(m_currentId);

    if (!query.exec()) {
        qWarning() << "Failed to close session:" << query.lastError();
    } else {
        qDebug() << "Closed session:" << stateToString(m_currentState) << duration << "s (ID:" << m_currentId << ")";
    }
    
    m_currentId = -1; // Reset ID
}

void ActivityLogger::startNewSession(TimerEngine::ActivityState state) {
    m_currentState = state;
    m_currentStartTime = QDateTime::currentDateTime();
    m_currentContent = "";
    m_currentWorkType = 0;
    
    if (!m_dbInitialized) return;

    // Insert immediately to persist the start of the session
    QSqlQuery query;
    query.prepare("INSERT INTO activity_log (state, start_time, end_time, duration, content, work_type) VALUES (?, ?, 0, 0, ?, ?)");
    query.addBindValue(stateToString(m_currentState));
    query.addBindValue(m_currentStartTime.toSecsSinceEpoch());
    query.addBindValue(m_currentContent);
    query.addBindValue(m_currentWorkType);

    if (query.exec()) {
        m_currentId = query.lastInsertId().toLongLong();
        qDebug() << "Started new session:" << stateToString(m_currentState) << "(ID:" << m_currentId << ")";
    } else {
        qWarning() << "Failed to start new session:" << query.lastError();
        m_currentId = -1;
    }
}

QString ActivityLogger::stateToString(TimerEngine::ActivityState state) {
    switch (state) {
        case TimerEngine::State_Focus: return "Focus";
        case TimerEngine::State_Rest: return "Rest";
        case TimerEngine::State_Nap: return "Nap";
        case TimerEngine::State_Pause: return "Pause";
        case TimerEngine::State_Offline: return "Offline";
        case TimerEngine::State_Ready: return "Ready";
        default: return "Unknown";
    }
}

int ActivityLogger::stateToColorType(TimerEngine::ActivityState state) {
    // Return an index for QML to map to colors
    return (int)state;
}

QVariantList ActivityLogger::getDailyActivities(const QDate& date) {
    QVariantList list;
    if (!m_dbInitialized) return list;

    QDateTime dayStart(date, QTime(0, 0, 0));
    QDateTime dayEnd(date, QTime(23, 59, 59));
    qint64 startTs = dayStart.toSecsSinceEpoch();
    qint64 endTs = dayEnd.toSecsSinceEpoch();

    QSqlQuery query;
    query.prepare("SELECT id, state, start_time, end_time, duration, content, work_type FROM activity_log WHERE start_time >= ? AND start_time <= ? AND end_time > 0 ORDER BY start_time ASC");
    query.addBindValue(startTs);
    query.addBindValue(endTs);

    if (query.exec()) {
        while (query.next()) {
            QVariantMap map;
            int id = query.value(0).toInt();
            QString stateStr = query.value(1).toString();
            qint64 sTime = query.value(2).toLongLong();
            qint64 eTime = query.value(3).toLongLong();
            int duration = query.value(4).toInt();
            QString content = query.value(5).toString();
            int workType = query.value(6).toInt();

            map["id"] = id;
            map["state"] = stateStr;
            map["startTime"] = sTime * 1000; // JS uses milliseconds
            map["endTime"] = eTime * 1000;
            map["duration"] = duration;
            map["content"] = content;
            map["workType"] = workType;
            
            // Map state string back to a display friendly name or type
            if (stateStr == "Focus") map["type"] = 0; // Blue
            else if (stateStr == "Rest") map["type"] = 1; // Green
            else if (stateStr == "Nap") map["type"] = 2; // Purple
            else if (stateStr == "Pause") map["type"] = 3; // Gray
            else map["type"] = 4; // Dark/Other

            list.append(map);
        }
    }
    
    // Add current ongoing session if it matches today
    if (m_currentStartTime.date() == date) {
         QVariantMap map;
         map["id"] = m_currentId; // Use real DB ID
         map["state"] = stateToString(m_currentState);
         map["startTime"] = m_currentStartTime.toSecsSinceEpoch() * 1000;
         map["endTime"] = QDateTime::currentDateTime().toSecsSinceEpoch() * 1000;
         map["duration"] = m_currentStartTime.secsTo(QDateTime::currentDateTime());
         map["type"] = (int)m_currentState;
         map["content"] = m_currentContent;
         map["workType"] = m_currentWorkType;
         map["isOngoing"] = true;
         list.append(map);
    }

    return list;
}

QVariantMap ActivityLogger::getDailyStats(const QDate& date) {
    QVariantMap stats;
    if (!m_dbInitialized) return stats;

    QDateTime dayStart(date, QTime(0, 0, 0));
    QDateTime dayEnd(date, QTime(23, 59, 59));
    qint64 startTs = dayStart.toSecsSinceEpoch();
    qint64 endTs = dayEnd.toSecsSinceEpoch();

    int totalFocus = 0;
    int totalRest = 0;
    int totalNap = 0;
    int totalPause = 0;
    
    int focusCount = 0; 
    
    int maxFocus = 0;
    int maxRest = 0;
    int maxPause = 0;
    int maxNap = 0;

    qint64 maxFocusStart = 0;
    qint64 maxRestStart = 0;
    qint64 maxPauseStart = 0;
    qint64 maxNapStart = 0;

    QSqlQuery query;
    // Use the same filtering logic as getDailyActivities to ensure consistency
    // Fetch all records for the day and aggregate manually, avoiding GROUP BY issues
    query.prepare("SELECT state, duration, start_time FROM activity_log WHERE start_time >= ? AND start_time <= ? AND end_time > 0");
    query.addBindValue(startTs);
    query.addBindValue(endTs);

    if (query.exec()) {
        while (query.next()) {
            QString state = query.value(0).toString();
            int duration = query.value(1).toInt();
            qint64 startTime = query.value(2).toLongLong() * 1000; // Convert to ms

            // Accumulate generic stats
            stats[state + "Duration"] = stats[state + "Duration"].toInt() + duration;
            stats[state + "Count"] = stats[state + "Count"].toInt() + 1;

            if (state == "Focus") {
                totalFocus += duration;
                if (duration > 1800) focusCount++; // Only count > 30min
                if (duration > maxFocus) {
                    maxFocus = duration;
                    maxFocusStart = startTime;
                }
            } else if (state == "Rest") {
                totalRest += duration;
                if (duration > maxRest) {
                    maxRest = duration;
                    maxRestStart = startTime;
                }
            } else if (state == "Nap") {
                totalNap += duration;
                if (duration > maxNap) {
                    maxNap = duration;
                    maxNapStart = startTime;
                }
            } else if (state == "Pause") {
                totalPause += duration;
                if (duration > maxPause) {
                    maxPause = duration;
                    maxPauseStart = startTime;
                }
            }
        }
    } else {
        qWarning() << "getDailyStats query failed:" << query.lastError();
    }

    // Add ongoing session if applicable
    if (m_currentStartTime.date() == date) {
        QString currentStateStr = stateToString(m_currentState);
        int currentDuration = m_currentStartTime.secsTo(QDateTime::currentDateTime());
        
        stats[currentStateStr + "Duration"] = stats[currentStateStr + "Duration"].toInt() + currentDuration;
        stats[currentStateStr + "Count"] = stats[currentStateStr + "Count"].toInt() + 1;
        
        qint64 currentStartMs = m_currentStartTime.toSecsSinceEpoch() * 1000;

        if (m_currentState == TimerEngine::State_Focus) {
             totalFocus += currentDuration;
             if (currentDuration > 1800) focusCount++; 
             if (currentDuration > maxFocus) {
                 maxFocus = currentDuration;
                 maxFocusStart = currentStartMs;
             }
        } else if (m_currentState == TimerEngine::State_Rest) {
             totalRest += currentDuration;
             if (currentDuration > maxRest) {
                 maxRest = currentDuration;
                 maxRestStart = currentStartMs;
             }
        } else if (m_currentState == TimerEngine::State_Nap) {
             totalNap += currentDuration;
             if (currentDuration > maxNap) {
                 maxNap = currentDuration;
                 maxNapStart = currentStartMs;
             }
        } else if (m_currentState == TimerEngine::State_Pause) {
             totalPause += currentDuration;
             if (currentDuration > maxPause) {
                 maxPause = currentDuration;
                 maxPauseStart = currentStartMs;
             }
        }
    }

    stats["totalFocusSeconds"] = totalFocus;
    stats["totalRestSeconds"] = totalRest;
    stats["totalNapSeconds"] = totalNap;
    stats["totalPauseSeconds"] = totalPause;
    
    stats["focusSessionCount"] = focusCount;
    
    stats["maxFocusSeconds"] = maxFocus;
    stats["maxRestSeconds"] = maxRest;
    stats["maxPauseSeconds"] = maxPause;
    stats["maxNapSeconds"] = maxNap;

    stats["maxFocusStart"] = maxFocusStart;
    stats["maxRestStart"] = maxRestStart;
    stats["maxPauseStart"] = maxPauseStart;
    stats["maxNapStart"] = maxNapStart;
    
    return stats;
}

bool ActivityLogger::updateActivityContent(int id, const QString& content, int workType) {
    if (!m_dbInitialized) return false;

    // Handle ongoing session update
    if (id == m_currentId) {
        m_currentContent = content;
        m_currentWorkType = workType;
        qDebug() << "Updated ongoing session content in memory:" << content;
    }

    QSqlQuery query;
    query.prepare("UPDATE activity_log SET content = ?, work_type = ? WHERE id = ?");
    query.addBindValue(content);
    query.addBindValue(workType);
    query.addBindValue(id);

    if (query.exec()) {
        qDebug() << "Updated activity content for ID:" << id;
        return true;
    } else {
        qWarning() << "Failed to update activity content:" << query.lastError();
        return false;
    }
}

QString ActivityLogger::generateReport(const QDate& date, int range, int mode) {
    if (!m_dbInitialized) return "Error: Database not initialized.";

    QDateTime startDt, endDt;
    endDt = QDateTime(date, QTime(23, 59, 59));

    if (range == 0) { // Day
        startDt = QDateTime(date, QTime(0, 0, 0));
    } else if (range == 1) { // Week (Mon - Today)
        // Find Monday
        QDate d = date;
        while (d.dayOfWeek() != 1) d = d.addDays(-1);
        startDt = QDateTime(d, QTime(0, 0, 0));
    } else if (range == 2) { // Month (1st - Today)
        startDt = QDateTime(QDate(date.year(), date.month(), 1), QTime(0, 0, 0));
    }

    qint64 startTs = startDt.toSecsSinceEpoch();
    qint64 endTs = endDt.toSecsSinceEpoch();
    
    // Convert ms
    return generateReportCustom(startTs * 1000, endTs * 1000, mode);
}

QString ActivityLogger::generateReportCustom(qint64 startMs, qint64 endMs, int mode) {
    if (!m_dbInitialized) return "Error: Database not initialized.";

    qint64 startTs = startMs / 1000;
    qint64 endTs = endMs / 1000;
    
    QDateTime startDt = QDateTime::fromSecsSinceEpoch(startTs);
    QDateTime endDt = QDateTime::fromSecsSinceEpoch(endTs);

    QSqlQuery query;
    // We only care about Focus Work (state='Focus') that has content
    QString sql = "SELECT start_time, end_time, duration, content, work_type FROM activity_log WHERE state='Focus' AND start_time >= ? AND start_time <= ? AND content IS NOT NULL AND content != '' ORDER BY start_time ASC";
    query.prepare(sql);
    query.addBindValue(startTs);
    query.addBindValue(endTs);

    if (!query.exec()) return "Error: Query failed " + query.lastError().text();

    QString report;
    report += "📅 工作汇报\n";
    report += "时间范围: " + startDt.toString("MM-dd") + " 至 " + endDt.toString("MM-dd") + "\n";
    if (mode == 0) report += "模式: 全景复盘 (个人)\n";
    else report += "模式: 职场汇报 (正式)\n";
    report += "----------------------------------------\n";

    int count = 0;
    while (query.next()) {
        qint64 sTime = query.value(0).toLongLong();
        qint64 eTime = query.value(1).toLongLong();
        int duration = query.value(2).toInt();
        QString content = query.value(3).toString();
        int workType = query.value(4).toInt();

        QDateTime sDt = QDateTime::fromSecsSinceEpoch(sTime);
        QDateTime eDt = QDateTime::fromSecsSinceEpoch(eTime);
        QString timeStr = QString("[%1 %2-%3] (%4m)")
            .arg(sDt.toString("MM-dd"))
            .arg(sDt.toString("HH:mm"))
            .arg(eDt.toString("HH:mm"))
            .arg(duration / 60);

        // Parse JSON content
        QString formal, learning, personal, memo, thought;
        bool isJson = content.trimmed().startsWith("{");
        
        if (isJson) {
            QJsonDocument doc = QJsonDocument::fromJson(content.toUtf8());
            if (!doc.isNull() && doc.isObject()) {
                QJsonObject obj = doc.object();
                formal = obj.value("formal").toString();
                learning = obj.value("learning").toString();
                personal = obj.value("personal").toString();
                memo = obj.value("memo").toString();
                thought = obj.value("thought").toString();
            } else {
                // Fallback to manual parsing if QJsonDocument fails (unlikely if valid JSON)
                // or just treat as raw content? Let's assume valid JSON or empty.
                qWarning() << "Failed to parse JSON content in report generation:" << content;
            }
        } else {
            // Legacy fallback: use workType to determine category
            // 0: Formal, 1: Learning, 2: Personal
            if (workType == 1) learning = content;
            else if (workType == 2) personal = content;
            else formal = content; // Default to formal (0 or others)
        }

        bool hasOutput = false;

        // Formal Work
        if (!formal.isEmpty()) {
            report += QString("%1 %2 %3\n").arg(mode == 0 ? "🔵" : "•").arg(timeStr).arg(formal);
            hasOutput = true;
        }

        // Learning (Skip in Leader Mode)
        if (mode == 0 && !learning.isEmpty()) {
            report += QString("🟢 %1 %2\n").arg(timeStr).arg(learning);
            hasOutput = true;
        }

        // Personal (Skip in Leader Mode)
        if (mode == 0 && !personal.isEmpty()) {
            report += QString("🟡 %1 %2\n").arg(timeStr).arg(personal);
            hasOutput = true;
        }

        // Memo (Skip in Leader Mode)
        if (mode == 0 && !memo.isEmpty()) {
            report += QString("🟣 %1 %2\n").arg(timeStr).arg(memo);
            hasOutput = true;
        }

        // Thought (Skip in Leader Mode)
        if (mode == 0 && !thought.isEmpty()) {
            report += QString("💠 %1 %2\n").arg(timeStr).arg(thought);
            hasOutput = true;
        }
        
        if (hasOutput) count++;
    }

    if (count == 0) report += "（无记录）\n";
    
    return report;
}

QVariantList ActivityLogger::getActiveDatesInMonth(int year, int month) {
    QVariantList list;
    if (!m_dbInitialized) return list;

    // Calculate start and end of month
    QDate startD(year, month + 1, 1); // JS month is 0-indexed, but Qt QDate is 1-indexed. Wait, caller usually passes JS month (0-11).
    // Let's assume input is 0-indexed (JS style) to match QML expectations, or 1-indexed?
    // QML CalendarPicker passes `currentMonth` which is 0-11.
    // So QDate expects 1-12.
    
    int qDateMonth = month + 1;
    QDate startDate(year, qDateMonth, 1);
    QDate endDate = startDate.addMonths(1).addDays(-1);
    
    qint64 startTs = QDateTime(startDate, QTime(0, 0, 0)).toSecsSinceEpoch();
    qint64 endTs = QDateTime(endDate, QTime(23, 59, 59)).toSecsSinceEpoch();

    QSqlQuery query;
    // We want days that have ANY activity.
    // Efficiently, we can just select all start_times and process in C++ since DB is local and small.
    // Or select DISTINCT date if using sqlite functions, but portability...
    // Let's just select start_time.
    
    query.prepare("SELECT start_time FROM activity_log WHERE start_time >= ? AND start_time <= ?");
    query.addBindValue(startTs);
    query.addBindValue(endTs);

    QSet<int> activeDays;

    if (query.exec()) {
        while (query.next()) {
            qint64 ts = query.value(0).toLongLong();
            QDateTime dt = QDateTime::fromSecsSinceEpoch(ts);
            // Local time day
            activeDays.insert(dt.date().day());
        }
    } else {
        qWarning() << "getActiveDatesInMonth query failed:" << query.lastError();
    }
    
    // Also check current ongoing session
    if (m_currentState != TimerEngine::State_Offline && m_currentStartTime.date().year() == year && m_currentStartTime.date().month() == qDateMonth) {
        activeDays.insert(m_currentStartTime.date().day());
    }

    for (int day : activeDays) {
        list.append(day);
    }
    
    return list;
}
