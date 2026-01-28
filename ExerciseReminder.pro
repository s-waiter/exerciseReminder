QT += core gui qml quick widgets svg
CONFIG += c++17

TARGET = ExerciseReminder
TEMPLATE = app

SOURCES += \
    src/main.cpp \
    src/core/TimerEngine.cpp \
    src/gui/TrayIcon.cpp

HEADERS += \
    src/core/TimerEngine.h \
    src/gui/TrayIcon.h

RESOURCES += resources.qrc

# High DPI support for Windows
windows:MANIFEST_DEPENDENCIES += "type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'"

# Fix for MSVC "C2001: newline in constant" error due to UTF-8 encoding with Chinese comments
msvc:QMAKE_CXXFLAGS += /utf-8
