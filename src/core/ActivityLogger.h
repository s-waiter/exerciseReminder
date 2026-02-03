#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QDateTime>
#include <QVariant>
#include "TimerEngine.h"

class ActivityLogger : public QObject {
    Q_OBJECT
public:
    explicit ActivityLogger(TimerEngine* engine, QObject *parent = nullptr);
    ~ActivityLogger();

    // QML Invokable methods
    Q_INVOKABLE QVariantList getDailyActivities(const QDate& date);
    Q_INVOKABLE QVariantMap getDailyStats(const QDate& date);
    Q_INVOKABLE bool updateActivityContent(int id, const QString& content, int workType);
    
    // Report Generation
    // range: 0=Day, 1=Week, 2=Month
    // mode: 0=Full(Self), 1=Formal(Leader)
    Q_INVOKABLE QString generateReport(const QDate& date, int range, int mode);

private slots:
    void onActivityStateChanged(TimerEngine::ActivityState newState);
    // 处理手动记录的运动
    void onManualExerciseRecorded(int durationSeconds);

private:
    void initDatabase();
    void closeCurrentSession(const QDateTime& endTime = QDateTime());
    void startNewSession(TimerEngine::ActivityState state);
    QString stateToString(TimerEngine::ActivityState state);
    int stateToColorType(TimerEngine::ActivityState state); // Returns an index or string for UI color mapping

    QSqlDatabase m_db;
    TimerEngine* m_engine;
    TimerEngine::ActivityState m_currentState;
    QDateTime m_currentStartTime;
    bool m_dbInitialized = false;
};
