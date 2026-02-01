#include "UpdaterWindow.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    
    // Check arguments
    QStringList args = a.arguments();
    if (args.count() < 4) {
        // For testing/debugging, provide defaults or exit
        // return -1; 
    }

    QString zipPath = args.value(1);
    QString installDir = args.value(2);
    QString appName = args.value(3);

    UpdaterWindow w(zipPath, installDir, appName);
    w.show();

    return a.exec();
}
