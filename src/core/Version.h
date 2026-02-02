#ifndef VERSION_H
#define VERSION_H

#include <QString>

#define APP_VERSION "1.0.3"
#define APP_VERSION_MAJOR 1
#define APP_VERSION_MINOR 0
#define APP_VERSION_PATCH 3

class Version {
public:
    static QString getCurrentVersion();
};

#endif // VERSION_H
