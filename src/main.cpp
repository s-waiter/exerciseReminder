#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QIcon>
#include "core/AppConfig.h"
#include "core/TimerEngine.h"
#include "gui/TrayIcon.h"
#include "utils/WindowUtils.h"

// main函数：程序的入口点
// argc: 命令行参数个数
// argv: 命令行参数数组
int main(int argc, char *argv[])
{
    // ========================================================================
    // 1. High DPI (高DPI) 设置
    // ========================================================================
    // 在 Qt 5 中，必须在创建 QApplication 对象之前设置此属性。
    // 这告诉 Qt 自动根据显示器的 DPI 缩放界面，防止在 4K 屏上界面太小。
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    // ========================================================================
    // 2. 应用程序实例
    // ========================================================================
    // QApplication 管理 GUI 程序的控制流和主要设置。
    // 它处理窗口系统事件（鼠标、键盘等）并将其分发给各窗口对象。
    // 注意：对于 QML 程序，通常使用 QGuiApplication 即可，但为了使用
    // QSystemTrayIcon (系统托盘) 这种传统的 Widget 组件，我们需要完整的 QApplication。
    QApplication app(argc, argv);
    
    // 关键设置：关闭最后一个窗口时不退出程序。
    // 默认情况下，Qt 程序在最后一个窗口关闭时会自动退出。
    // 但我们的程序需要常驻系统托盘，所以必须禁用此行为。
    app.setQuitOnLastWindowClosed(false);

    // ========================================================================
    // 3. 初始化 C++ 核心模块 (后端逻辑)
    // ========================================================================
    // 这里实例化了我们在 C++ 中编写的业务逻辑类。
    // 它们都继承自 QObject，以便与 QML 进行交互。
    
    TimerEngine timerEngine; // 计时器逻辑核心
    TrayIcon trayIcon;       // 系统托盘图标控制
    AppConfig appConfig;     // 配置管理 (读写注册表/配置文件)
    WindowUtils windowUtils; // 窗口工具 (处理置顶等原生 API)

    // ========================================================================
    // 4. 连接 C++ 内部信号与槽 (Signals & Slots)
    // ========================================================================
    // 信号与槽是 Qt 的核心机制，用于对象间通信，类似于观察者模式。
    // 当 timerEngine 发出 timeUpdated 信号时，执行 lambda 表达式更新托盘提示。
    
    QObject::connect(&timerEngine, &TimerEngine::timeUpdated, [&](){
        // 获取剩余秒数
        int secs = timerEngine.remainingSeconds();
        // 格式化字符串
        QString tip = QString("久坐提醒: 剩余 %1 分钟").arg(secs / 60);
        // 更新托盘图标的鼠标悬停提示
        trayIcon.updateToolTip(tip);
    });

    // 连接托盘菜单的 "退出" 请求到应用程序的 quit 槽函数。
    // 当用户点击托盘菜单的退出时，程序终止。
    QObject::connect(&trayIcon, &TrayIcon::quitRequested, &app, &QApplication::quit);

    // ========================================================================
    // 5. 初始化 QML 引擎 (前端加载)
    // ========================================================================
    // QQmlApplicationEngine 负责加载 QML 文件并管理 QML 上下文。
    QQmlApplicationEngine engine;
    
    // ========================================================================
    // 6. 依赖注入：将 C++ 对象暴露给 QML
    // ========================================================================
    // 通过 rootContext()->setContextProperty，我们可以将 C++ 对象的指针注入到 QML 全局命名空间。
    // 这样在 QML 文件中，就可以直接使用 "timerEngine"、"appConfig" 等变量名来调用 C++ 的方法和属性。
    // 这是 Qt Quick 中 C++ (后端) 与 QML (前端) 交互最简单直接的方式。
    
    engine.rootContext()->setContextProperty("timerEngine", &timerEngine);
    engine.rootContext()->setContextProperty("trayIcon", &trayIcon);
    engine.rootContext()->setContextProperty("appConfig", &appConfig);
    engine.rootContext()->setContextProperty("windowUtils", &windowUtils);

    // 加载主界面 QML 文件
    // qrc:/ 表示从 Qt 资源系统 (Resource System) 中加载，而不是从磁盘路径加载。
    // 资源文件会被编译进 exe 中，方便分发。
    const QUrl url(QStringLiteral("qrc:/assets/qml/Main.qml"));
    
    // 安全检查：监听 objectCreated 信号，确保 QML 加载成功。
    // 如果 QML 文件有语法错误导致加载失败，obj 会是空指针，此时程序应退出并返回错误码 -1。
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    // 开始加载
    engine.load(url);

    // ========================================================================
    // 7. 进入主事件循环
    // ========================================================================
    // app.exec() 会启动 Qt 的事件循环 (Event Loop)。
    // 它会一直运行，直到调用了 quit() 或 exit()。
    // 在此期间，它会处理鼠标点击、定时器事件、重绘请求等。
    return app.exec();
}
