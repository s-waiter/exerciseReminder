#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QIcon>
#include <QLocalServer>
#include <QLocalSocket>
#include <QWindow>
#include "core/AppConfig.h"
#include "core/TimerEngine.h"
#include "core/UpdateManager.h"
#include "core/StatisticsManager.h"
#include "gui/TrayIcon.h"
#include "utils/WindowUtils.h"

/*
我已经为您完成了所有源代码文件的详细中文注释添加工作。这些注释不仅解释了代码“做了什么”，更重要的是解释了“为什么要这样做”以及背后的 Qt 核心机制，非常适合作为学习材料。

### 核心 C++ 部分 (src/ 目录)
我重点解释了 Qt 的元对象系统和 C++ 与 QML 的交互机制：

1. src/main.cpp (程序的入口)
   
   - 知识点 ：解释了 QApplication 的初始化、高分屏 (High DPI) 设置、以及如何使用 QQmlApplicationEngine 加载 QML 界面。
   - 关键点 ：展示了如何将 C++ 对象（ TimerEngine , AppConfig ）注入到 QML 上下文中，这是混合开发的核心。
2. src/core/TimerEngine.h/cpp (核心业务逻辑)
   
   - 知识点 ：详细注释了 Q_OBJECT 宏的作用（元对象系统）、 Q_PROPERTY 属性系统（如何让 C++ 变量在 QML 中通过属性绑定自动更新）、以及 Signal/Slot （信号与槽）机制。
   - 学习建议 ：重点阅读 Q_PROPERTY 的声明和 emit 信号发送的部分，这是 Qt 响应式编程的基础。
3. src/core/AppConfig.h/cpp (配置管理)
   
   - 知识点 ：解释了 QSettings 的用法，它是 Qt 提供的跨平台配置存储方案（在 Windows 上自动读写注册表）。
   - 实战 ：注释了如何通过修改注册表 HKCU\Software\Microsoft\Windows\CurrentVersion\Run 实现开机自启。
4. src/utils/WindowUtils.h/cpp (底层窗口工具)
   
   - 知识点 ：展示了如何使用 Q_INVOKABLE 宏将普通 C++ 函数暴露给 QML 调用。
   - 进阶 ：解释了如何调用 Windows 原生 API ( SetWindowPos ) 来解决 Qt 默认置顶方式在某些情况下闪烁的问题。
### QML 界面部分 (assets/qml/ 目录)
我详细拆解了声明式 UI 的结构和动画逻辑：

1. assets/qml/Main.qml (主界面)
   
   - 知识点 ：解释了 Window 属性、无边框窗口 ( FramelessWindowHint ) 的实现、以及如何使用 MouseArea 手动实现窗口拖拽。
   - 动画 ：详细注释了 Behavior (属性行为) 动画，展示了如何让窗口大小和位置的变化如丝般顺滑。
   - 绘图 ：解释了 Canvas 组件如何使用 JavaScript 绘制动态倒计时圆环。
2. assets/qml/OverlayWindow.qml (全屏提醒遮罩)
   
   - 知识点 ：讲解了 Loader 组件如何动态加载不同的视觉主题（圆环、六边形、雷达），这是一种高效的内存管理和组件复用方式。
   - 特效 ：注释了 ParticleSystem (粒子系统) 的配置，解释了如何创建庆祝气泡特效。
   - 交互 ：展示了全屏遮罩、鼠标穿透拦截以及玻璃拟态 (Glassmorphism) 的实现细节。
建议您从 main.cpp 开始阅读，理解程序启动流程，然后对照 TimerEngine.h 和 Main.qml 学习 C++ 后端如何驱动前端界面更新。祝您 Qt 学习愉快！
*/

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

    // 设置应用程序信息 (用于 QSettings) 和图标
    app.setOrganizationName("TraeAI");
    app.setApplicationName("FocusTimer");
    app.setWindowIcon(QIcon(":/assets/logo.png"));

    // ========================================================================
    // 2.5 单实例检查 (Single Instance Check)
    // ========================================================================
    // 需求：当用户已经启动了一个实例，再次双击 exe 时，不应启动新实例，而是唤醒已有实例。
    // 实现：使用 QLocalServer/QLocalSocket (基于命名管道/Unix域套接字) 进行进程间通信。
    
    const QString serverName = "TraeAI_DeskCare_SingleInstance_Lock";
    QLocalSocket socket;
    socket.connectToServer(serverName);
    
    // 尝试连接已存在的服务器
    if (socket.waitForConnected(500)) {
        qDebug() << "Another instance is running. Waking it up...";
        // 发送唤醒消息
        socket.write("WAKE_UP");
        socket.waitForBytesWritten(1000);
        socket.disconnectFromServer();
        
        // 退出当前新实例
        return 0;
    }
    
    // 如果连接失败，说明是第一个实例 (或上一个实例崩溃留下了僵尸文件)
    // 清理可能存在的残留连接文件 (Windows下通常自动清理，但在Unix下很有必要，这里统一处理以防万一)
    QLocalServer::removeServer(serverName);
    
    // 创建单实例服务器
    QLocalServer singleInstanceServer;
    if (!singleInstanceServer.listen(serverName)) {
        qWarning() << "Failed to listen on single instance server:" << singleInstanceServer.errorString();
        // 即使监听失败，程序也继续运行，只是失去了防多开功能
    }

    // 3.0 Check command line arguments for auto-start
    bool isAutoStartLaunch = false;
    for (int i = 1; i < argc; ++i) {
        if (QString(argv[i]) == "--autostart") {
            isAutoStartLaunch = true;
            break;
        }
    }
    
    // ========================================================================
    // 3. 初始化 C++ 核心模块 (后端逻辑)
    // ========================================================================
    // 这里实例化了我们在 C++ 中编写的业务逻辑类。
    // 它们都继承自 QObject，以便与 QML 进行交互。
    
    TimerEngine timerEngine; // 计时器逻辑核心
    UpdateManager updateManager; // 更新管理器
    StatisticsManager statsManager; // 用户统计管理器
    TrayIcon trayIcon(&timerEngine, &updateManager);       // 系统托盘图标控制
    AppConfig appConfig;     // 配置管理 (读写注册表/配置文件)
    WindowUtils windowUtils; // 窗口工具 (处理置顶等原生 API)

    // 启动时上报用户活跃数据 (DAU)
    statsManager.reportStartup();

    // ========================================================================
    // 4. 连接 C++ 内部信号与槽 (Signals & Slots)
    // ========================================================================
    // 信号与槽是 Qt 的核心机制，用于对象间通信，类似于观察者模式。
    // 托盘图标内部已经处理了 TimerEngine 的信号，这里不再需要手动连接。

    // 连接系统锁屏信号到计时器引擎
    QObject::connect(&windowUtils, &WindowUtils::sessionStateChanged, 
                     &timerEngine, &TimerEngine::handleSystemLock);

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
    engine.rootContext()->setContextProperty("updateManager", &updateManager);
    engine.rootContext()->setContextProperty("trayIcon", &trayIcon);
    engine.rootContext()->setContextProperty("appConfig", &appConfig);
    engine.rootContext()->setContextProperty("windowUtils", &windowUtils);
    engine.rootContext()->setContextProperty("isAutoStartLaunch", isAutoStartLaunch);

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
    // 6.5 处理单实例唤醒信号
    // ========================================================================
    // 当收到第二个实例的连接请求时，将主窗口置顶显示
    QObject::connect(&singleInstanceServer, &QLocalServer::newConnection, &app, [&]() {
        QLocalSocket* clientConnection = singleInstanceServer.nextPendingConnection();
        if (!clientConnection) return;
        
        clientConnection->close();
        clientConnection->deleteLater();
        
        // 获取主窗口并激活
        if (engine.rootObjects().isEmpty()) return;
        
        QObject* rootObject = engine.rootObjects().first();
        QWindow* window = qobject_cast<QWindow*>(rootObject);
        
        if (window) {
            // 如果窗口是隐藏的（如在托盘），显示它
            window->setVisible(true);
            
            // 恢复正常状态（如果是最小化）
            if (window->visibility() == QWindow::Minimized) {
                window->showNormal();
            }
            
            // 尝试将窗口置顶并获取焦点
            window->raise();
            window->requestActivate();
            
            // 针对 Windows 平台的强力置顶 Hack (防止 requestActivate 被操作系统拦截)
            // 有时 OS 会阻止后台程序抢占焦点，通过模拟最小化再恢复可以绕过
            // 但对于无边框窗口，直接 raise + requestActivate 通常足够，
            // 配合 WindowUtils 的 setTopMost 可以确保效果。
        }
    });

    // ========================================================================
    // 7. 进入主事件循环
    // ========================================================================
    // app.exec() 会启动 Qt 的事件循环 (Event Loop)。
    // 它会一直运行，直到调用了 quit() 或 exit()。
    // 在此期间，它会处理鼠标点击、定时器事件、重绘请求等。
    return app.exec();
}
