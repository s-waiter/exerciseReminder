#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QIcon>
#include "core/AppConfig.h"
#include "core/TimerEngine.h"
#include "gui/TrayIcon.h"

int main(int argc, char *argv[])
{
    // 1. High DPI 设置 (Qt 5 必须在 QApplication 构造前设置)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    // 2. 使用 QApplication 以支持 QSystemTrayIcon (Widgets 模块)
    QApplication app(argc, argv);
    
    // 关键：关闭最后一个窗口时不退出程序（因为我们需要常驻托盘）
    app.setQuitOnLastWindowClosed(false);

    // 3. 初始化核心模块
    TimerEngine timerEngine;
    TrayIcon trayIcon;
    AppConfig appConfig;

    // 4. 连接 C++ 内部信号
    // 当计时器更新时，更新托盘提示信息
    QObject::connect(&timerEngine, &TimerEngine::timeUpdated, [&](){
        int secs = timerEngine.remainingSeconds();
        QString tip = QString("久坐提醒: 剩余 %1 分钟").arg(secs / 60);
        trayIcon.updateToolTip(tip);
    });

    // 响应托盘菜单的退出请求
    QObject::connect(&trayIcon, &TrayIcon::quitRequested, &app, &QApplication::quit);

    // 5. 初始化 QML 引擎
    QQmlApplicationEngine engine;
    
    // 将 C++ 对象注入到 QML 上下文中，使其在 QML 中全局可用
    // 在 QML 中可以直接使用 `timerEngine` 和 `trayIcon` 标识符
    engine.rootContext()->setContextProperty("timerEngine", &timerEngine);
    engine.rootContext()->setContextProperty("trayIcon", &trayIcon);
    engine.rootContext()->setContextProperty("appConfig", &appConfig);

    // 加载主 QML 文件
    const QUrl url(QStringLiteral("qrc:/assets/qml/Main.qml"));
    
    // 安全加载检查
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    engine.load(url);

    return app.exec();
}
