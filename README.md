# DeskCare (久坐提醒助手)

## 项目简介
这是一个基于 Qt 5.15 和 C++ 17 开发的久坐提醒工具 DeskCare。程序常驻系统托盘，每隔 45 分钟会弹出全屏窗口提醒用户休息运动。

## 编译指南

### 前置要求
*   **Qt 5.15** (MinGW 或 MSVC 版本均可)
*   **C++ 编译器** (支持 C++17)

### 编译步骤

#### 方法一：使用 Qt Creator (推荐)
1.  打开 Qt Creator。
2.  点击“打开项目”，选择本项目根目录下的 `DeskCare.pro` 文件。
3.  配置项目构建套件 (Kit)。
4.  点击左下角的 **构建 (Build)** 按钮（或按 `Ctrl+B`）。

#### 方法二：使用命令行 (qmake)
1.  打开 Qt 命令行终端 (如 "Qt 5.15.2 (MinGW 8.1.0) 64-bit")。
2.  进入项目目录：
    ```bash
    cd c:\Users\admin\Desktop\trae\DeskCare
    ```
    *(注：如果文件夹名未修改，仍为 exerciseReminder)*
3.  生成 Makefile：
    ```bash
    qmake
    ```
4.  编译：
    *   如果是 MinGW: `mingw32-make`
    *   如果是 MSVC: `nmake`

## 功能说明
*   **托盘图标**: 程序启动后会最小化到托盘。右键点击托盘图标可退出程序或显示设置界面。
*   **设置界面**: 点击托盘图标可打开，查看剩余时间和手动测试提醒。
*   **全屏提醒**: 倒计时结束后自动弹出全屏覆盖窗口。
*   **稍后提醒**: 全屏界面点击“稍后提醒”将推迟 5 分钟。

## 目录结构
*   `src/`: C++ 源代码
*   `assets/qml/`: QML 界面文件
*   `resources.qrc`: 资源配置文件
*   `DeskCare.pro`: qmake 项目文件
