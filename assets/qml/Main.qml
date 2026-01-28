import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQml 2.15 // for Instantiator
import QtGraphicalEffects 1.15 // 需要在 pro 中添加 QT += graphicaleffects (如果是动态编译) 或者直接使用

// 注意：如果 GraphicalEffects 不可用，可以移除相关效果。
// 为了确保兼容性，这里尽量使用基础图形或 Canvas。

Window {
    id: mainWindow
    width: 360
    height: 520
    visible: false
    title: "久坐提醒助手"
    color: "transparent" // 透明背景，为了自定义圆角或异形窗口（如果 flag 允许）
    
    // 窗口标志：去除默认标题栏，自定义边框
    flags: Qt.FramelessWindowHint | Qt.Window
    
    // 拖拽窗口逻辑
    MouseArea {
        anchors.fill: parent
        property point lastMousePos: Qt.point(0, 0)
        onPressed: { lastMousePos = Qt.point(mouseX, mouseY); }
        onPositionChanged: {
            if (pressed) {
                var dx = mouseX - lastMousePos.x
                var dy = mouseY - lastMousePos.y
                mainWindow.x += dx
                mainWindow.y += dy
            }
        }
    }

    // 主背景容器
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 20
        clip: true
        
        // 高科技感渐变背景
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#141E30"
            } // 深蓝黑
            GradientStop {
                position: 1.0
                color: "#243B55"
            } // 深灰蓝
        }

        // 装饰性光晕
        Rectangle {
            width: 300
            height: 300
            radius: 150
            color: "#00d2ff"
            opacity: 0.05
            x: -50
            y: -50
        }
        
        // 顶部标题栏区域
        Item {
            id: titleBar
            width: parent.width
            height: 50
            anchors.top: parent.top
            
            Text {
                text: "EXERCISE REMINDER"
                color: "#8899A6"
                font.pixelSize: 12
                font.letterSpacing: 2
                font.bold: true
                anchors.centerIn: parent
            }

            // 关闭/隐藏按钮
            Button {
                width: 30
                height: 30
                anchors.right: parent.right
                anchors.rightMargin: 15
                anchors.verticalCenter: parent.verticalCenter
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: "×"
                    color: "white"
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: mainWindow.hide()
            }
        }

        // 核心内容区
        Column {
            anchors.centerIn: parent
            spacing: 30
            
            // 1. 环形进度条 + 时间显示
            Item {
                width: 220
                height: 220
                anchors.horizontalCenter: parent.horizontalCenter
                
                // 外圈轨道
                Rectangle {
                    anchors.fill: parent
                    radius: width/2
                    color: "transparent"
                    border.color: "#33ffffff"
                    border.width: 4
                }

                // 进度圆环 (Canvas 绘制)
                Canvas {
                    id: progressCanvas
                    anchors.fill: parent
                    rotation: -90 // 从12点方向开始
                    
                    // 绑定属性以便重绘
                    property double progress: timerEngine.remainingSeconds / (45 * 60.0)
                    onProgressChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        var centerX = width / 2;
                        var centerY = height / 2;
                        var radius = width / 2 - 4; // 减去边框宽度
                        
                        ctx.clearRect(0, 0, width, height);
                        
                        // 绘制进度弧
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, 0, Math.PI * 2 * progress, false);
                        ctx.lineWidth = 8;
                        ctx.lineCap = "round";
                        
                        // 渐变色画笔
                        var gradient = ctx.createLinearGradient(0, 0, width, height);
                        gradient.addColorStop(0, "#00d2ff"); // 青色
                        gradient.addColorStop(1, "#3a7bd5"); // 蓝色
                        ctx.strokeStyle = gradient;
                        
                        ctx.stroke();
                    }
                }
                
                // 中心时间文字
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    
                    Text {
                        property int mins: Math.floor(timerEngine.remainingSeconds / 60)
                        property int secs: timerEngine.remainingSeconds % 60
                        // 补零格式化
                        text: (mins < 10 ? "0"+mins : mins) + ":" + (secs < 10 ? "0"+secs : secs)
                        color: "#ffffff"
                        font.pixelSize: 48
                        font.family: "Segoe UI Light" // 细体字更有科技感
                        font.weight: Font.Light
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: timerEngine.statusText
                        color: "#00d2ff"
                        font.pixelSize: 14
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.8
                    }
                }
            }
            
            // 2. 状态/数据面板
            Row {
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter
                
                // 间隔设置卡片
                Rectangle {
                    width: 100
                    height: 60
                    color: "#1Affffff"
                    radius: 10
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsPopup.open()
                    }
                    
                    Column {
                        anchors.centerIn: parent
                        Text { 
                            // 安全访问属性，如果未定义(旧C++)则显示默认值
                            property var val: timerEngine.workDurationMinutes
                            text: (val !== undefined ? val : 45) + " MIN"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text { 
                            text: "INTERVAL"
                            color: "#8899A6"
                            font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                
                // 模式显示卡片
                Rectangle {
                    width: 100
                    height: 60
                    color: "#1Affffff"
                    radius: 10
                    
                    Column {
                        anchors.centerIn: parent
                        Text { 
                            text: "WORK"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text { 
                            text: "MODE"
                            color: "#8899A6"
                            font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // 设置弹窗
            Popup {
                id: settingsPopup
                anchors.centerIn: parent
                width: 260
                height: 180
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                
                background: Rectangle {
                    color: "#243B55"
                    radius: 15
                    border.color: "#00d2ff"
                    border.width: 1
                }
                
                Column {
                    anchors.centerIn: parent
                    spacing: 20
                    
                    Text {
                        text: "设置提醒间隔"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Row {
                        spacing: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Button {
                            width: 40
                            height: 40
                            text: "-"
                            background: Rectangle {
                                color: parent.down ? "#1Affffff" : "transparent"
                                radius: 20
                                border.color: "white"
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font.pixelSize: 20
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                if(timerEngine.workDurationMinutes !== undefined && timerEngine.workDurationMinutes > 1) {
                                    timerEngine.workDurationMinutes -= 1
                                }
                            }
                        }
                        
                        Text {
                            property var val: timerEngine.workDurationMinutes
                            text: (val !== undefined ? val : 45) + " 分钟"
                            color: "#00d2ff"
                            font.pixelSize: 20
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Button {
                            width: 40
                            height: 40
                            text: "+"
                            background: Rectangle {
                                color: parent.down ? "#1Affffff" : "transparent"
                                radius: 20
                                border.color: "white"
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font.pixelSize: 20
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                if(timerEngine.workDurationMinutes !== undefined && timerEngine.workDurationMinutes < 120) {
                                    timerEngine.workDurationMinutes += 1
                                }
                            }
                        }
                    }
                }
            }

            // 3. 底部操作按钮
            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter
                
                // 自定义按钮组件
                component CyberButton : Button {
                    property string btnColor: "#3a7bd5"
                    
                    background: Rectangle {
                        color: parent.down ? Qt.darker(btnColor, 1.2) : btnColor
                        radius: 25
                        border.width: 1
                        border.color: "#55ffffff"
                        
                        // 按钮光效
                        layer.enabled: parent.hovered
                        // 简单模拟发光，不依赖 GraphicalEffects
                        Rectangle {
                            anchors.fill: parent
                            radius: 25
                            color: "white"
                            opacity: parent.parent.hovered ? 0.1 : 0
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    width: 120
                    height: 45
                }

                CyberButton {
                    text: "立即休息"
                    btnColor: "#3a7bd5"
                    onClicked: {
                        themeController.generateRandomTheme()
                        isReminderActive = true
                    }
                }

                CyberButton {
                    text: "重置"
                    btnColor: "#2C3E50"
                    onClicked: timerEngine.startWork()
                }
            }
        }
    }

    // 主题控制器
    ThemeController {
        id: themeController
    }
    
    // 全局提醒激活状态
    property bool isReminderActive: false

    // 多屏实例化全屏提醒窗口
    Instantiator {
        model: Qt.application.screens
        delegate: OverlayWindow {
            screen: modelData // 绑定到对应屏幕
            themeData: themeController.currentTheme
            visible: isReminderActive
            
            onReminderFinished: isReminderActive = false
            onSnoozeRequested: {
                timerEngine.snooze()
                isReminderActive = false
            }
        }
    }

    // 连接信号
    Connections {
        target: trayIcon
        function onShowSettingsRequested() {
            mainWindow.visible = true
            mainWindow.raise()
            mainWindow.requestActivate()
            // 居中显示在屏幕
            mainWindow.x = (Screen.width - mainWindow.width) / 2
            mainWindow.y = (Screen.height - mainWindow.height) / 2
        }
    }

    Connections {
        target: timerEngine
        function onReminderTriggered() {
            themeController.generateRandomTheme()
            isReminderActive = true
        }
    }
}
