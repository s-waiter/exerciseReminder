#pragma once
#include <QDate>
#include <QString>
#include <QVector>

struct LunarDate {
    int year;
    int month;
    int day;
    bool isLeap; // Whether this month is the leap month
    
    bool isValid() const { return year > 0 && month > 0 && day > 0; }
    QString toString() const;
};

class LunarCalendar {
public:
    // Convert Gregorian date to Lunar date
    static LunarDate solarToLunar(const QDate& solarDate);
    
    // Convert Lunar date to Gregorian date
    // Note: If isLeap is true, it tries to convert the leap month. 
    // If the year doesn't have that leap month, it falls back to normal month or returns invalid.
    static QDate lunarToSolar(int year, int month, int day, bool isLeap = false);
    
    // Get friendly string (e.g., "八月初九")
    static QString getLunarDateString(const QDate& solarDate);
    static QString getLunarMonthString(int month);
    static QString getLunarDayString(int day);

private:
    static int getLunarYearDays(int year);
    static int getLeapMonth(int year);
    static int getLeapMonthDays(int year);
    static int getMonthDays(int year, int month);
    
    static const int MIN_YEAR = 1900;
    static const int MAX_YEAR = 2100;
    static const int LUNAR_INFO[];
    static const QDate BASE_DATE;
};
