QT += core gui widgets
TARGET = Updater
TEMPLATE = app

SOURCES += main.cpp \
           UpdaterWindow.cpp

HEADERS += UpdaterWindow.h 

# Default icon
# RC_ICONS = ../../assets/images/tray_icon.ico

win32: LIBS += -luser32

# Fix for MSVC "C2001: newline in constant" error due to UTF-8 encoding
msvc:QMAKE_CXXFLAGS += /utf-8

# Request Administrator privileges for Updater (Critical for writing to Program Files)
win32-msvc* {
    QMAKE_LFLAGS += /MANIFESTUAC:level=\'requireAdministrator\'
}
