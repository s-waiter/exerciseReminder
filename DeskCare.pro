QT += core gui qml quick widgets svg network
CONFIG += c++17

TARGET = DeskCare
TEMPLATE = app

SOURCES += \
    src/main.cpp \
    src/core/TimerEngine.cpp \
    src/gui/TrayIcon.cpp \
    src/core/AppConfig.cpp \
    src/utils/WindowUtils.cpp \
    src/core/UpdateManager.cpp \
    src/core/StatisticsManager.cpp \
    src/core/Version.cpp

HEADERS += \
    src/core/TimerEngine.h \
    src/gui/TrayIcon.h \
    src/core/AppConfig.h \
    src/utils/WindowUtils.h \
    src/core/UpdateManager.h \
    src/core/StatisticsManager.h \
    src/core/Version.h

RESOURCES += resources.qrc

# High DPI support for Windows
windows:MANIFEST_DEPENDENCIES += "type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'"
win32:LIBS += -luser32 -lwtsapi32

# Fix for MSVC "C2001: newline in constant" error due to UTF-8 encoding with Chinese comments
msvc:QMAKE_CXXFLAGS += /utf-8
