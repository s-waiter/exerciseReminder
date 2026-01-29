import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQml 2.15 // 引入 Instantiator 等高级 QML 功能
import QtGraphicalEffects 1.15 // 引入图形特效（如圆角裁剪、阴影、模糊）

// ========================================================================
// Main.qml - 应用程序主窗口
// ========================================================================
// 这是程序的主界面，包含倒计时圆环、状态显示和设置面板。
// 采用了无边框窗口设计 (Frameless Window) 和半透明背景。
// ========================================================================

Window {
    id: mainWindow
    
    // 动态调整窗口大小：
    // isPinned (迷你模式): 260x260
    // Normal (正常模式): 360x520
    width: isPinned ? 260 : 360
    height: isPinned ? 260 : 520
    visible: true
    title: "久坐提醒助手"
    color: "transparent" // 窗口背景完全透明，由内部 Rectangle 绘制实际背景
    
    // ========================================================================
    // 窗口标志 (Window Flags)
    // ========================================================================
    // Qt.FramelessWindowHint: 去除操作系统的标题栏和边框，完全自定义 UI。
    // Qt.Window: 这是一个顶级窗口。
    property bool isPinned: false
    flags: Qt.FramelessWindowHint | Qt.Window

    // ========================================================================
    // 属性动画 (Behavior)
    // ========================================================================
    // 当 width, height, x, y 发生变化时，不立即突变，而是应用缓动动画。
    // duration: 300ms
    // easing.type: Easing.OutQuint (五次方的缓出曲线，开始快结束慢，手感自然)
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    // ========================================================================
    // 动态主题色逻辑
    // ========================================================================
    // 根据 timerEngine (C++ 后端) 的状态改变 UI 主色调。
    // property 绑定会自动更新，无需手动监听信号。
    property color themeColor: {
        switch(timerEngine.statusText) {
            case "已暂停": return "#ffbf00" // 琥珀金 - 提示状态
            case "请休息": return "#00ff88" // 春日绿 - 休息状态
            default: return "#00d2ff"       // 科技蓝 - 工作状态
        }
    }
    
    // ========================================================================
    // 模式切换与视觉补偿
    // ========================================================================
    onIsPinnedChanged: {
        // 调用 C++ 工具类设置窗口置顶
        windowUtils.setTopMost(mainWindow, isPinned)
        
        // 视觉位置补偿逻辑：
        // 当切换模式时，窗口尺寸会发生变化。默认情况下，窗口左上角 (0,0) 不变，
        // 这会导致内容看起来向左上方收缩。
        // 为了让视觉中心（倒计时圆环）看起来还在原来的位置，我们需要反向移动窗口坐标。
        // 
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
    
    // ========================================================================
    // 窗口拖拽逻辑
    // ========================================================================
    // 由于去掉了系统标题栏，我们需要自己实现窗口拖拽。
    MouseArea {
        id: windowMouseArea
        anchors.fill: parent
        hoverEnabled: true // 启用悬停检测，用于迷你模式下显示标题栏
        property point lastMousePos: Qt.point(0, 0)
        
        onPressed: { lastMousePos = Qt.point(mouseX, mouseY); }
        
        onPositionChanged: {
            if (pressed) {
                // 计算鼠标位移差量 (dx, dy)
                var dx = mouseX - lastMousePos.x
                var dy = mouseY - lastMousePos.y
                // 更新窗口位置
                mainWindow.x += dx
                mainWindow.y += dy
            }
        }
    }

    // ========================================================================
    // UI 内容构建
    // ========================================================================
    
    // 主背景容器
    Item {
        id: bgContainer
        anchors.fill: parent
        
        // 使用 OpacityMask 实现完美的圆角裁剪
        // 这是 QtGraphicalEffects 的功能，比简单的 Rectangle.radius 效果更好，且支持子项裁剪。
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: bgContainer.width
                height: bgContainer.height
                // 迷你模式下变成圆形 (width/2)，正常模式下是大圆角 (20)
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

            // 装饰性光晕 (呼吸灯效果)
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
                
                // 位置平滑过渡
                Behavior on x { NumberAnimation { duration: 200 } }
                Behavior on y { NumberAnimation { duration: 200 } }
                
                // 呼吸动画：透明度在 0.05 到 0.15 之间循环
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
            
            // 迷你模式下自动隐藏/显示：鼠标移入时显示，移出隐藏
            opacity: isPinned ? (windowMouseArea.containsMouse ? 1.0 : 0.0) : 1.0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Text {
                text: "久坐提醒助手"
                color: "#8899A6"
                font.pixelSize: 12
                font.letterSpacing: 2
                font.bold: true
                anchors.centerIn: parent
                visible: !mainWindow.isPinned // 迷你模式不显示标题文字
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
                    // 点击并不是真正退出程序，而是隐藏窗口到托盘 (C++ SystemTray 逻辑处理)
                    onClicked: mainWindow.hide()
                }
            }
        }

        // ========================================================================
        // 核心内容区
        // ========================================================================
        
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
            // Canvas 是 QtQuick 中用于 2D 绘图的元素，类似于 HTML5 Canvas。
            Canvas {
                id: progressCanvas
                anchors.fill: parent
                rotation: -90 // 旋转 -90 度，让起始点从 12 点钟方向开始
                
                // 绑定属性以便重绘
                property double progress: {
                    var total = timerEngine.currentSessionTotalTime
                    // 避免除以 0
                    return total > 0 ? timerEngine.remainingSeconds / total : 0
                }
                property color drawColor: mainWindow.themeColor
                
                // 当 progress 或 drawColor 变化时，请求重新绘制
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
                    // arc 参数: x, y, radius, startAngle, endAngle, antiClockwise
                    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2 * progress, false);
                    ctx.lineWidth = 8;
                    ctx.lineCap = "round"; // 圆头线帽
                    
                    // 创建线性渐变色画笔
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
                    // 使用 Math.floor 取整
                    property int mins: Math.floor(timerEngine.remainingSeconds / 60)
                    property int secs: timerEngine.remainingSeconds % 60
                    // 补零格式化: 9:5 -> 09:05
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

            // 交互层：点击暂停/继续，双击切换置顶
            MouseArea {
                id: centerMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true // 开启悬停以显示详细 ETA
                
                // 支持拖拽窗口 (即使在圆环上也能拖拽)
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
                        
                        // 判断是否发生拖拽（设定 3 像素阈值），防止误触点击
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
                // 原理：单击后等待 250ms，如果没有发生双击，则触发单击事件。
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
        // 仅在 Normal 模式下显示
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
                        // 支持鼠标滚轮直接调节时长
                        onWheel: {
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
                        
                        // 自定义简约 Switch 控件
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
                                // 根据开关状态计算 x 坐标
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

            // 设置弹窗 (Popup)
            Popup {
                id: settingsPopup
                anchors.centerIn: parent
                width: 260
                height: 230
                modal: true // 模态对话框，遮挡背景
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
                        
                        // 减号按钮
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