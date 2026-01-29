import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQml 2.15 // for Instantiator
import QtGraphicalEffects 1.15

Window {
    id: mainWindow
    width: isPinned ? 260 : 360
    height: isPinned ? 260 : 520
    visible: true
    title: "久坐提醒助手"
    color: "transparent"
    
    // 窗口标志：去除默认标题栏，自定义边框
    property bool isPinned: false
    flags: Qt.FramelessWindowHint | Qt.Window

    // 窗口几何属性动画：确保窗口变形和位移同步，实现平滑过渡
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    // 动态主题色逻辑
    property color themeColor: {
        switch(timerEngine.statusText) {
            case "已暂停": return "#ffbf00" // 琥珀金
            case "请休息": return "#00ff88" // 春日绿
            default: return "#00d2ff"       // 科技蓝
        }
    }
    
    onIsPinnedChanged: {
        windowUtils.setTopMost(mainWindow, isPinned)
        
        // 视觉位置补偿逻辑：
        // 当切换模式时，调整窗口坐标，使得倒计时圆圈在屏幕上的绝对位置保持不变，消除视觉抖动。
        // 计算依据：
        // 1. 水平方向：Normal宽360(中心180) -> Mini宽260(中心130)。差值 50。
        //    切换到 Mini (变窄)，内容相对窗口左移了，为了保持视觉位置，窗口需右移 50。
        // 2. 垂直方向：Normal TopMargin 70 -> Mini TopMargin 20。差值 50。
        //    切换到 Mini (上移)，内容相对窗口上移了，为了保持视觉位置，窗口需下移 50。
        
        if (isPinned) {
            mainWindow.x += 50
            mainWindow.y += 50
        } else {
            mainWindow.x -= 50
            mainWindow.y -= 50
        }
    }
    
    // 拖拽窗口逻辑
    MouseArea {
        id: windowMouseArea
        anchors.fill: parent
        hoverEnabled: true // 启用悬停检测，用于迷你模式显示控件
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
    Item {
        id: bgContainer
        anchors.fill: parent
        
        // 使用 OpacityMask 实现完美的圆角裁剪
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: bgContainer.width
                height: bgContainer.height
                radius: isPinned ? width / 2 : 20
                visible: false
            }
        }

        Rectangle {
            id: bgRect
            anchors.fill: parent
            // radius: isPinned ? width / 2 : 20 // 移除 radius 和 clip，由 OpacityMask 接管
            // clip: true
            
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
                id: glowRect
                // 迷你模式下居中，正常模式下保持在左上角
                width: 300
                height: 300
                radius: 150
                color: mainWindow.themeColor
                opacity: 0.05
                x: isPinned ? (parent.width - width) / 2 : -50
                y: isPinned ? (parent.height - height) / 2 : -50
                Behavior on x { NumberAnimation { duration: 200 } }
                Behavior on y { NumberAnimation { duration: 200 } }
                
                // 呼吸动画
                SequentialAnimation on opacity {
                    running: timerEngine.statusText === "工作中"
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.05; to: 0.15; duration: 2000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.15; to: 0.05; duration: 2000; easing.type: Easing.InOutQuad }
                }
            }
            
            // 顶部标题栏区域
            Item {
            id: titleBar
            width: parent.width
            height: isPinned ? 40 : 50
            anchors.top: parent.top
            z: 10 
            
            // 迷你模式下自动隐藏/显示
            opacity: isPinned ? (windowMouseArea.containsMouse ? 1.0 : 0.0) : 1.0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Text {
                text: "久坐提醒助手"
                color: "#8899A6"
                font.pixelSize: 12
                font.letterSpacing: 2
                font.bold: true
                anchors.centerIn: parent
                visible: !mainWindow.isPinned
            }

            // 按钮容器，用于在不同模式下调整位置
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 15
                anchors.top: parent.top
                anchors.topMargin: 10
                spacing: 5
                
                // 关闭/隐藏按钮
                Button {
                    id: closeBtn
                    width: 30
                    height: 30
                    visible: !mainWindow.isPinned // 迷你模式下隐藏关闭按钮，防止误触，只留取消置顶
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
        }

        // 核心内容区
        
        // 1. 环形进度条 + 时间显示 (独立于 Column，固定位置)
        Item {
            id: circleItem
            width: 220
            height: 220
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            // Normal模式下下移 70px 以避开标题栏，Mini模式下仅保留 20px 边距居中
            // 配合 onIsPinnedChanged 中的窗口坐标补偿，实现视觉位置静止
            anchors.topMargin: isPinned ? 20 : 70
            
            // 关键：Margin 动画必须与窗口几何动画完全同步 (duration/easing 一致)
            // 这样 WindowY(t) + TopMargin(t) = Constant，从而消除视觉抖动
            Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            
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
                property color drawColor: mainWindow.themeColor
                onProgressChanged: requestPaint()
                onDrawColorChanged: requestPaint()

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
                    gradient.addColorStop(0, drawColor); // 主色
                    gradient.addColorStop(1, "#3a7bd5"); // 蓝色 (可以保持蓝色基调，或者也跟随变化？跟随变化更好)
                    // 让尾部稍微偏蓝一点，保持科技感
                    if (drawColor == "#ffbf00") {
                            gradient.addColorStop(1, "#ff9100"); // 琥珀色的渐变尾
                    } else if (drawColor == "#00ff88") {
                            gradient.addColorStop(1, "#00bfa5"); // 绿色的渐变尾
                    }
                    
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
                    color: mainWindow.themeColor
                    font.pixelSize: 14
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: 0.8
                }

                // 预计结束时间 (ETA)
                Text {
                    text: "预计 " + timerEngine.estimatedFinishTime + " 休息"
                    color: "#8899A6" // 弱化显示
                    font.pixelSize: 12
                    // 使用 opacity 控制显示，避免 visible 导致的布局抖动
                    opacity: timerEngine.statusText === "工作中" ? 0.6 : 0.0
                    visible: true 
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    // 平滑过渡
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }

            // 交互层：点击暂停/继续
            MouseArea {
                id: centerMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true // 开启悬停以显示详细 ETA
                
                // 支持拖拽窗口
                property point clickPos
                property bool isDrag: false
                
                onPressed: {
                    clickPos = Qt.point(mouseX, mouseY)
                    isDrag = false
                    // lastPos 用于计算位移增量
                    lastPos = Qt.point(mouseX, mouseY)
                }
                
                property point lastPos
                onPositionChanged: {
                    if(pressed) {
                        var dx = mouseX - lastPos.x
                        var dy = mouseY - lastPos.y
                        
                        // 判断是否发生拖拽（设定 3 像素阈值）
                        if (!isDrag && (Math.abs(mouseX - clickPos.x) > 3 || Math.abs(mouseY - clickPos.y) > 3)) {
                            isDrag = true
                        }
                        
                        mainWindow.x += dx
                        mainWindow.y += dy
                    }
                }
                
                onClicked: {
                    // 只有在非拖拽情况下才触发暂停
                    if (!isDrag) {
                        clickTimer.start()
                    }
                }
                
                onDoubleClicked: {
                    // 双击切换置顶状态
                    if (!isDrag) {
                        clickTimer.stop() // 停止单击计时器，防止触发暂停
                        mainWindow.isPinned = !mainWindow.isPinned
                    }
                }
                
                // 单击延迟计时器，用于区分单击和双击
                Timer {
                    id: clickTimer
                    interval: 250 // 标准双击间隔阈值
                    repeat: false
                    onTriggered: {
                        timerEngine.togglePause()
                    }
                }
            }
        }
        
        // 2. 状态/数据面板 (独立于 Column，定位在圆圈下方)
        Row {
            id: statusRow
            spacing: 20
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: circleItem.bottom
            anchors.topMargin: 30
            visible: !mainWindow.isPinned
            height: visible ? implicitHeight : 0 // 确保隐藏时不占位
                
                // 间隔设置卡片
                Rectangle {
                    id: intervalCard
                    width: 100
                    height: 60
                    color: "#1Affffff"
                    radius: 10
                    border.color: intervalMouseArea.containsMouse ? mainWindow.themeColor : "transparent"
                    border.width: 1
                    
                    // 悬停缩放效果
                    scale: intervalMouseArea.containsMouse ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    MouseArea {
                        id: intervalMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: settingsPopup.open()
                        onWheel: {
                            // 滚轮快速调节
                            var delta = wheel.angleDelta.y > 0 ? 1 : -1
                            var newVal = timerEngine.workDurationMinutes + delta
                            if (newVal >= 1 && newVal <= 120) {
                                timerEngine.workDurationMinutes = newVal
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        
                        Text { 
                            property var val: timerEngine.workDurationMinutes
                            text: (val !== undefined ? val : 45) + " min"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 16
                            font.family: "Segoe UI"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text { 
                            text: "间隔时长"
                            color: "#8899A6"
                            font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                
                // 开机自启卡片 (极简 Switch 风格)
                Rectangle {
                    id: autoStartCard
                    width: 100
                    height: 60
                    color: "#1Affffff"
                    radius: 10
                    border.color: autoStartMouseArea.containsMouse ? mainWindow.themeColor : "transparent"
                    border.width: 1
                    
                    // 悬停缩放效果
                    scale: autoStartMouseArea.containsMouse ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    MouseArea {
                        id: autoStartMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: appConfig.autoStart = !appConfig.autoStart
                    }
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        
                        // 自定义简约 Switch
                        Rectangle {
                            width: 36
                            height: 20
                            radius: 10
                            color: appConfig.autoStart ? mainWindow.themeColor : "#33ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            
                            // 滑块
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                x: appConfig.autoStart ? parent.width - width - 2 : 2
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                            }
                        }
                        
                        Text {
                            text: "开机自启"
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
                height: 230
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
                anchors.top: statusRow.bottom
                anchors.topMargin: 30
                visible: !mainWindow.isPinned
                height: visible ? implicitHeight : 0
                
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