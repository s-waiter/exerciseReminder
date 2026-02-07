#include "LunarCalendar.h"
#include <QDebug>

// Lunar Calendar Data (1900-2100)
// Source: https://github.com/isee15/Lunar-Solar-Calendar-Converter
// 0x04bd8 etc.
// Bits 0-3: Leap Month Index (0 if none)
// Bits 4-15: Month Days (1=30, 0=29) - Bit 15 is Month 1
// Bit 16: Leap Month Days (0=29, 1=30) - (If Leap > 0)
// Note: 0x04bd8 -> 0000 0100 1011 1101 1000
// Leap=8. LeapSize=0(29). Months=0x4bd (0100 1011 1101)

const int LunarCalendar::LUNAR_INFO[] = {
    0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,
    0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,
    0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,
    0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,
    0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,
    0x06ca0,0x0b550,0x15355,0x04da0,0x0a5d0,0x14573,0x052d0,0x0a9a8,0x0e950,0x06aa0,
    0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,
    0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b5a0,0x195a6,
    0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,
    0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x055c0,0x0ab60,0x096d5,0x092e0,
    0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,
    0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,
    0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530,
    0x05aa0,0x076a3,0x096d0,0x04bd7,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,
    0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,
    0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06b20,0x1a6c4,0x0aae0,
    0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,
    0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,
    0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,
    0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252,
    0x0d520 // 2100
};

const QDate LunarCalendar::BASE_DATE = QDate(1900, 1, 31);

int LunarCalendar::getLeapMonth(int year) {
    if (year < MIN_YEAR || year >= MIN_YEAR + 201) return 0;
    return LUNAR_INFO[year - MIN_YEAR] & 0xf;
}

int LunarCalendar::getLeapMonthDays(int year) {
    if (year < MIN_YEAR || year >= MIN_YEAR + 201) return 0;
    return (LUNAR_INFO[year - MIN_YEAR] & 0x10000) ? 30 : 29;
}

int LunarCalendar::getMonthDays(int year, int month) {
    if (year < MIN_YEAR || year >= MIN_YEAR + 201) return 29;
    // Month is 1-12
    // Bit 15 is Month 1. Bit 14 is Month 2...
    return (LUNAR_INFO[year - MIN_YEAR] & (0x10000 >> month)) ? 30 : 29;
}

int LunarCalendar::getLunarYearDays(int year) {
    int days = 0;
    for (int i = 1; i <= 12; i++) {
        days += getMonthDays(year, i);
    }
    int leap = getLeapMonth(year);
    if (leap > 0) {
        days += getLeapMonthDays(year);
    }
    return days;
}

LunarDate LunarCalendar::solarToLunar(const QDate& solarDate) {
    LunarDate lunar = {0, 0, 0, false};
    int i, leap = 0, temp = 0;
    
    qint64 offset = BASE_DATE.daysTo(solarDate);
    if (offset < 0) return lunar;

    for (i = MIN_YEAR; i <= MAX_YEAR; i++) {
        temp = getLunarYearDays(i);
        if (offset < temp) break;
        offset -= temp;
    }

    lunar.year = i;
    leap = getLeapMonth(i);
    lunar.isLeap = false;

    for (i = 1; i <= 12; i++) {
        temp = getMonthDays(lunar.year, i);
        if (offset < temp) {
            lunar.month = i;
            lunar.day = offset + 1;
            break;
        }
        offset -= temp;
        
        if (leap == i) {
            temp = getLeapMonthDays(lunar.year);
            if (offset < temp) {
                lunar.month = i;
                lunar.day = offset + 1;
                lunar.isLeap = true;
                break;
            }
            offset -= temp;
        }
    }
    return lunar;
}

QDate LunarCalendar::lunarToSolar(int year, int month, int day, bool isLeap) {
    QDate date = BASE_DATE;
    qint64 offset = 0;
    
    for (int i = MIN_YEAR; i < year; i++) {
        offset += getLunarYearDays(i);
    }
    
    int leap = getLeapMonth(year);
    for (int i = 1; i < month; i++) {
        offset += getMonthDays(year, i);
        if (leap == i) {
            offset += getLeapMonthDays(year);
        }
    }
    
    if (isLeap && leap == month) {
        offset += getMonthDays(year, month);
    }
    
    offset += (day - 1);
    
    return date.addDays(offset);
}

QString LunarCalendar::getLunarDateString(const QDate& solarDate) {
    LunarDate l = solarToLunar(solarDate);
    QString s = QString("%1年%2%3").arg(l.year)
                 .arg(l.isLeap ? "闰" : "")
                 .arg(getLunarMonthString(l.month));
    s += getLunarDayString(l.day);
    return s;
}

QString LunarCalendar::getLunarMonthString(int month) {
    static const QStringList months = {
        "", "正月", "二月", "三月", "四月", "五月", "六月", 
        "七月", "八月", "九月", "十月", "冬月", "腊月"
    };
    if (month >= 1 && month <= 12) return months[month];
    return "未知";
}

QString LunarCalendar::getLunarDayString(int day) {
    static const QStringList days = {
        "", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    };
    if (day >= 1 && day <= 30) return days[day];
    return "未知";
}

QString LunarDate::toString() const {
    return QString("%1年%2%3%4").arg(year)
            .arg(isLeap ? "闰" : "")
            .arg(LunarCalendar::getLunarMonthString(month))
            .arg(LunarCalendar::getLunarDayString(day));
}
