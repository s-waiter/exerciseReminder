import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Particles 2.0 // 引入粒子系统
import QtGraphicalEffects 1.15

// ========================================================================
// OverlayWindow.qml - 全屏遮罩提醒窗口
// ========================================================================
// 这是倒计时结束时弹出的全屏强制提醒界面。
// 包含粒子特效、多种视觉主题（圆环、六边形、雷达）和反馈动画。
// ========================================================================

Window {
    id: overlayWin
    visible: false
    // 强制全屏 + 置顶 + 无边框
    // Qt.WindowStaysOnTopHint: 确保在所有窗口最上层
    flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
    
    // 显式设置几何属性以防止某些环境下显示异常
    width: Screen.width
    height: Screen.height
    x: 0
    y: 0
    
    // visibility: Window.FullScreen // 移除初始的 visibility 设置，避免冲突
    color: "transparent"

    // -------------------------------------------------------------------------
    // 外部接口 (API)
    // -------------------------------------------------------------------------

    // 主题数据 (由外部 TimerEngine.cpp 传入)
    // 包含颜色配置、图标、视觉样式等
    property var themeData: ({})
    
    // 信号 (Signals)：用于通知 C++ 后端
    signal reminderFinished() // 提醒流程结束（用户点击完成或超时）
    signal snoozeRequested()  // 用户请求贪睡（暂未实现）

    // 窗口可见性改变时的逻辑
    onVisibleChanged: {
        if(visible) {
            // 确保几何属性正确 (防止多屏环境下的位置偏移)
            width = Screen.width
            height = Screen.height
            x = 0
            y = 0
            
            showTime = new Date()
            
            // 初始化强制运动倒计时
            if (appConfig && appConfig.forcedExercise) {
                totalForcedDuration = appConfig.forcedExerciseDuration * 60
                remainingForcedSeconds = totalForcedDuration
                forcedCountdownTimer.restart()
            } else {
                remainingForcedSeconds = 0
            }

            showFullScreen() // 确保全屏
            raise()          // 提升窗口层级
            // 重启动画
            mainEntranceAnim.restart()
        } else {
            // 隐藏时重置状态
            feedbackText = ""
        }
    }

    // 兼容旧代码的别名，避免修改大量内部引用
    property alias currentTheme: overlayWin.themeData

    // -------------------------------------------------------------------------
    // 交互层 (Interaction)
    // -------------------------------------------------------------------------
    // 全屏鼠标追踪 (用于视差特效)
    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled: true // 启用悬停检测
        acceptedButtons: Qt.NoButton // 不拦截点击，让点击穿透到下面的按钮
        z: 1000 // 放在最上层以捕获所有鼠标移动 (但 acceptedButtons: NoButton 会让点击穿透)
    }

    // -------------------------------------------------------------------------
    // UI 实现
    // -------------------------------------------------------------------------

    // 0. 反馈状态
    property string feedbackText: ""
    property var showTime: null
    
    // 新增统计数据属性
    property int todayTotalSeconds: 0
    property var weeklyStats: []
    property var todaySessions: [] // 今日所有会话详情
    property string sessionTimeRange: ""

    // ========================================================================
    // 强制运动倒计时逻辑
    // ========================================================================
    property int remainingForcedSeconds: 0
    property int totalForcedDuration: 0
    property bool isForcedLocked: remainingForcedSeconds > 0

    Timer {
        id: forcedCountdownTimer
        interval: 100 // 10Hz 刷新以保证进度条平滑
        repeat: true
        running: visible && appConfig && appConfig.forcedExercise && remainingForcedSeconds > 0
        onTriggered: {
            if (!overlayWin.showTime) return
            var now = new Date()
            var elapsed = Math.floor((now - overlayWin.showTime) / 1000)
            var required = appConfig.forcedExerciseDuration * 60
            
            // 更新剩余时间
            var rem = Math.max(0, required - elapsed)
            if (rem !== remainingForcedSeconds) {
                remainingForcedSeconds = rem
            }
            
            // 确保总时长正确 (防止配置在运行时改变)
            totalForcedDuration = required
        }
    }

    // 自动关闭计时器 - 已移除，改由 feedbackLayer 的倒计时动画驱动


    // ========================================================================
    // 反馈遮罩层 (Feedback Layer)
    // ========================================================================
    // 当用户完成运动后显示的结算界面
    Rectangle {
        id: feedbackLayer
        anchors.fill: parent
        color: "transparent"
        visible: overlayWin.feedbackText !== "" // 只有有反馈文本时才显示
        z: 1001 // 确保最顶层 (高于 mouseTracker z:1000)

        // 1. 背景模糊与变暗 (沉浸式呼吸 + 视差)
        Rectangle {
            id: immersiveBg
            anchors.fill: parent
            color: "#CC000510" // 80% 不透明度的深色背景
            
            // 呼吸因子 (0.85 ~ 1.0)
            property real breathingFactor: 1.0
            
            // 最终透明度 = 显隐状态 * 呼吸因子
            opacity: (feedbackLayer.visible ? 1.0 : 0.0) * breathingFactor
            Behavior on opacity { NumberAnimation { duration: 500 } }

            // 初始放大，防止视差移动露出边缘
            scale: 1.05
            
            // 视差特效：跟随鼠标反向微动 (0.01系数)
            transform: Translate {
                x: (overlayWin.width/2 - mouseTracker.mouseX) * 0.01
                y: (overlayWin.height/2 - mouseTracker.mouseY) * 0.01
            }

            // 沉浸式呼吸动画 (4秒吸 4秒呼)
            ParallelAnimation {
                running: feedbackLayer.visible
                loops: Animation.Infinite
                
                // 缩放呼吸 (1.05 -> 1.10)
                SequentialAnimation {
                    NumberAnimation { target: immersiveBg; property: "scale"; to: 1.10; duration: 4000; easing.type: Easing.InOutSine }
                    NumberAnimation { target: immersiveBg; property: "scale"; to: 1.05; duration: 4000; easing.type: Easing.InOutSine }
                }
                // 明暗呼吸 (呼吸因子 1.0 -> 0.85)
                SequentialAnimation {
                    NumberAnimation { target: immersiveBg; property: "breathingFactor"; to: 0.85; duration: 4000; easing.type: Easing.InOutSine }
                    NumberAnimation { target: immersiveBg; property: "breathingFactor"; to: 1.0; duration: 4000; easing.type: Easing.InOutSine }
                }
            }
        }

        // 2. 庆祝粒子系统 (从底部升起的金色气泡)
        ParticleSystem {
            id: celebrationSys
            anchors.fill: parent
            running: feedbackLayer.visible
            
            ItemParticle {
                delegate: Rectangle {
                    width: Math.random() * 6 + 2
                    height: width
                    radius: width/2
                    color: currentTheme.gradientEnd
                    opacity: 0.6
                }
                fade: true // 粒子生命周期结束时自动淡出
            }

            Emitter {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                emitRate: 20
                lifeSpan: 4000
                size: 10
                sizeVariation: 5
                velocity: PointDirection { y: -200; yVariation: 100 } // 向上飘动
                acceleration: PointDirection { y: -50 }
            }
        }

        // 3. 核心卡片容器 (结算信息)
        Item {
            id: resultCard
            width: 600
            height: 580
            anchors.centerIn: parent
            
            // 进场动画：从下往上浮现 + 缩放
            transform: [
                Translate {
                    y: feedbackLayer.visible ? 0 : 100
                    Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                },
                Scale {
                    origin.x: resultCard.width/2
                    origin.y: resultCard.height/2
                    // 悬停时放大 (1.05)，增强交互感
                    xScale: feedbackLayer.visible ? (feedbackMouseArea.containsMouse ? 1.05 : 1.0) : 0.8
                    yScale: feedbackLayer.visible ? (feedbackMouseArea.containsMouse ? 1.05 : 1.0) : 0.8
                    Behavior on xScale { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
                    Behavior on yScale { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
                }
            ]
            opacity: feedbackLayer.visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 400 } }

            // 卡片背景 (玻璃拟态 Glassmorphism)
            Rectangle {
                id: cardBg
                anchors.fill: parent
                radius: 24
                color: "#D91a1a1a" // 深灰半透
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)
                
                // 内部微光
                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.05) }
                        GradientStop { position: 0.4; color: "transparent" }
                    }
                }

                // 鼠标交互区域 (仅限卡片范围)
                MouseArea { 
                    id: feedbackMouseArea
                    anchors.fill: parent 
                    hoverEnabled: true // 开启悬停检测
                    preventStealing: true
                }
            }
            
            // 阴影
            DropShadow {
                anchors.fill: cardBg
                horizontalOffset: 0
                verticalOffset: 20
                radius: 40
                samples: 17
                color: "#80000000"
                source: cardBg
            }

            // 卡片内容
            Column {
                anchors.centerIn: parent
                spacing: 25
                
                // A. 动态勋章
                Item {
                    width: 160
                    height: 160
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    // 外圈旋转光环
                    Rectangle {
                        anchors.fill: parent
                        radius: width/2
                        color: "transparent"
                        border.width: 2
                        border.color: Qt.rgba(currentTheme.gradientEnd.r, currentTheme.gradientEnd.g, currentTheme.gradientEnd.b, 0.3)
                        
                        RotationAnimation on rotation {
                            running: overlayWin.visible
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 10000
                        }
                    }
                    
                    // 进度圆环 (Canvas 绘制 - 绘制一个闭合的圆)
                    Canvas {
                        id: progressCanvas
                        anchors.fill: parent
                        property real angle: 0
                        property color arcColor: currentTheme.gradientEnd
                        
                        onAngleChanged: requestPaint()
                        onArcColorChanged: requestPaint()
                        
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.beginPath();
                            // 动态绘制圆弧
                            ctx.arc(width/2, height/2, width/2 - 8, -Math.PI/2, -Math.PI/2 + angle, false);
                            ctx.lineWidth = 8;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = arcColor;
                            ctx.stroke();
                        }
                        
                        // 动画驱动：从 0 到 360 度 (2*PI)
                        SequentialAnimation on angle {
                            running: feedbackLayer.visible
                            PauseAnimation { duration: 300 }
                            NumberAnimation { from: 0; to: Math.PI * 2; duration: 1000; easing.type: Easing.OutQuart }
                        }
                    }
                    
                    // 中心对勾 (Checkmark)
                    Text {
                        anchors.centerIn: parent
                        text: "✔"
                        color: "white"
                        font.pixelSize: 60
                        scale: 0
                        
                        // 弹跳动画
                        SequentialAnimation on scale {
                            running: feedbackLayer.visible
                            PauseAnimation { duration: 800 } // 等圆环画完一半再出来
                            NumberAnimation { from: 0; to: 1.2; duration: 300; easing.type: Easing.OutBack }
                            NumberAnimation { from: 1.2; to: 1.0; duration: 100 }
                        }
                    }
                }
                
                // B. 统计信息区域 (替代原来的简单文字)
                Column {
                    spacing: 15
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    // 1. 本次运动概览
                    Column {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            text: overlayWin.feedbackText
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter // 确保居中对齐
                            
                            // 简单的出现动画
                            opacity: 0
                            NumberAnimation on opacity {
                                running: feedbackLayer.visible
                                from: 0; to: 1; duration: 500
                            }
                        }
                        
                        Text {
                            text: "时间段: " + overlayWin.sessionTimeRange
                            color: "#aaffffff"
                            font.pixelSize: 14
                            anchors.horizontalCenter: parent.horizontalCenter // 确保居中对齐
                            visible: overlayWin.sessionTimeRange !== ""
                        }
                    }
                    
                    // 2. 分隔线
                    Rectangle {
                        width: 100
                        height: 1
                        color: "#33ffffff"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // 3. 今日累计
                    Text {
                        text: {
                            var total = overlayWin.todayTotalSeconds
                            var h = Math.floor(total / 3600)
                            var m = Math.floor((total % 3600) / 60)
                            var s = total % 60
                            
                            var timeStr = ""
                            if (h > 0) {
                                timeStr = h + "小时" + m + "分钟"
                            } else if (m > 0) {
                                timeStr = m + "分钟" + s + "秒"
                            } else {
                                timeStr = s + "秒"
                            }
                            
                            return "今日累计运动: " + timeStr
                        }
                        color: currentTheme.gradientEnd // 使用主题色高亮
                        font.pixelSize: 16
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    // 4. 数据展示区域 (水平布局：左侧周趋势，右侧今日时间轴)
                    Row {
                        spacing: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        // 4.1 近7天趋势图表
                        Item {
                            width: 320
                            height: 160
                            
                            // 图表背景
                            Rectangle {
                                anchors.fill: parent
                                color: "#11ffffff"
                                radius: 10
                            }
                            
                            // 标题
                            Text {
                                text: "近7天运动趋势"
                                color: "#66ffffff"
                                font.pixelSize: 10
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 8
                            }
                            
                            Row {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 5
                                spacing: 15
                                
                                Repeater {
                                    model: overlayWin.weeklyStats
                                    delegate: Column {
                                        spacing: 5
                                        property real maxVal: {
                                            var m = 60 // 默认最小基准
                                            for(var i=0; i<overlayWin.weeklyStats.length; i++) {
                                                if(overlayWin.weeklyStats[i].seconds > m) m = overlayWin.weeklyStats[i].seconds
                                            }
                                            return m
                                        }
                                        
                                        property real barH: (modelData.seconds / maxVal) * 80 // 增加一点高度 (60->80)
                                        
                                        // 柱状条容器
                                        Rectangle {
                                            width: 20
                                            height: 80 
                                            color: "transparent"
                                            
                                            // 实际的柱子 (底部对齐)
                                            Rectangle {
                                                width: parent.width
                                                height: Math.max(2, barH) // 至少2px高度
                                                color: modelData.isToday ? currentTheme.gradientEnd : "#44ffffff"
                                                radius: 2
                                                anchors.bottom: parent.bottom
                                                
                                                // 动画: 每次显示时重启动画
                                                property bool isVisible: feedbackLayer.visible
                                                onIsVisibleChanged: {
                                                    if(isVisible) {
                                                        heightAnimation.restart()
                                                    }
                                                }
                                                
                                                NumberAnimation on height {
                                                    id: heightAnimation
                                                    from: 0; to: Math.max(2, barH)
                                                    duration: 800; easing.type: Easing.OutBack 
                                                }
                                            }
                                        }
                                        
                                        // 日期
                                        Text {
                                            text: modelData.date
                                            color: modelData.isToday ? "white" : "#66ffffff"
                                            font.pixelSize: 10
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }
                            }
                        }

                        // 4.2 今日时间轴 (Timeline)
                        Item {
                            width: 220
                            height: 160
                            
                            // 背景
                            Rectangle {
                                anchors.fill: parent
                                color: "#11ffffff"
                                radius: 10
                            }
                            
                            // 标题
                            Text {
                                text: "今日运动记录 (" + overlayWin.todaySessions.length + ")"
                                color: "#66ffffff"
                                font.pixelSize: 10
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 8
                            }

                            // 列表视图
                            ListView {
                                id: sessionList
                                anchors.fill: parent
                                anchors.topMargin: 30
                                anchors.bottomMargin: 10
                                clip: true
                                model: overlayWin.todaySessions
                                spacing: 8
                                
                                // 添加滚动条
                                ScrollBar.vertical: ScrollBar {
                                    active: true
                                    width: 4
                                    background: Rectangle { color: "transparent" }
                                    contentItem: Rectangle {
                                        implicitWidth: 4
                                        implicitHeight: 100
                                        radius: 2
                                        color: "#33ffffff"
                                    }
                                }
                                
                                delegate: Item {
                                    width: sessionList.width
                                    height: 24
                                    
                                    // 时间轴连线 (装饰)
                                    Rectangle {
                                        width: 1
                                        height: parent.height + 8
                                        color: "#33ffffff"
                                        x: 20
                                        visible: index < sessionList.count - 1
                                        anchors.top: dot.bottom
                                    }
                                    
                                    // 时间点圆点
                                    Rectangle {
                                        id: dot
                                        width: 6; height: 6
                                        radius: 3
                                        color: currentTheme.gradientEnd
                                        x: 17
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    // 时间段文本 "13:50-13:51"
                                    Text {
                                        text: modelData.start + " - " + modelData.end
                                        color: "white"
                                        font.pixelSize: 12
                                        anchors.left: dot.right
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    // 时长文本 "60s"
                                    Text {
                                        text: modelData.duration + "s"
                                        color: "#88ffffff"
                                        font.pixelSize: 11
                                        anchors.right: parent.right
                                        anchors.rightMargin: 15
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                
                                // 滚动条自动滚动到底部 (显示最新)
                                onCountChanged: {
                                    Qt.callLater(function() { positionViewAtEnd() })
                                }
                            }
                        }
                    }
                }
                
                // C. 底部倒计时条
                Item {
                    width: 500
                    height: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        text: feedbackMouseArea.containsMouse ? "已暂停 (移开鼠标继续)" : "正在恢复工作模式..."
                        color: "#66ffffff"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }
                    
                    // 进度条
                    Rectangle {
                        anchors.bottom: parent.bottom
                        // 使用 3000ms (3秒) 作为新的展示时长
                        width: parent.width * (3000 - closeTimerCountdown.elapsed) / 3000
                        height: 2
                        color: currentTheme.gradientEnd
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        // 倒计时动画辅助属性
                        Item {
                            id: closeTimerCountdown
                            property int elapsed: 0
                            NumberAnimation on elapsed {
                                id: countdownAnim
                                running: feedbackLayer.visible
                                paused: feedbackMouseArea.containsMouse // 悬停暂停
                                from: 0; to: 3000; duration: 3000
                                onFinished: overlayWin.reminderFinished() // 动画结束触发关闭
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // 提醒主背景 (Reminder Background)
    // ========================================================================
    // 1. 动态渐变背景
    Rectangle {
        id: bg
        anchors.fill: parent
        // 初始放大一点，防止视差移动时露出边缘
        scale: 1.05 
        
        // 视差特效 (Parallax Effect)
        // 让背景跟随鼠标反向微动，增加深邃感
        transform: Translate {
            x: (overlayWin.width/2 - mouseTracker.mouseX) * 0.01
            y: (overlayWin.height/2 - mouseTracker.mouseY) * 0.01
        }

        gradient: Gradient {
            GradientStop { 
                position: 0.0 
                color: currentTheme.gradientStart 
                Behavior on color { ColorAnimation { duration: 1000 } }
            }
            GradientStop { 
                position: 1.0 
                color: currentTheme.gradientEnd 
                Behavior on color { ColorAnimation { duration: 1000 } }
            }
        }
        
        // 沉浸式呼吸 (Immersive Breathing)
        // 4秒一吸，4秒一呼，配合不透明度变化
        ParallelAnimation {
            running: overlayWin.visible
            loops: Animation.Infinite
            
            // 呼吸缩放 (1.05 -> 1.10 -> 1.05)
            SequentialAnimation {
                NumberAnimation { target: bg; property: "scale"; to: 1.10; duration: 4000; easing.type: Easing.InOutSine }
                NumberAnimation { target: bg; property: "scale"; to: 1.05; duration: 4000; easing.type: Easing.InOutSine }
            }
            
            // 呼吸明暗
            SequentialAnimation {
                NumberAnimation { target: bg; property: "opacity"; to: 0.85; duration: 4000; easing.type: Easing.InOutSine }
                NumberAnimation { target: bg; property: "opacity"; to: 1.0; duration: 4000; easing.type: Easing.InOutSine }
            }
        }
    }

    // 2. 粒子系统 (Ambient Particles)
    ParticleSystem {
        id: particles
        anchors.fill: parent
        // 视差特效 (层级更深，移动稍快，营造立体感)
        transform: Translate {
            x: (overlayWin.width/2 - mouseTracker.mouseX) * 0.03
            y: (overlayWin.height/2 - mouseTracker.mouseY) * 0.03
        }
        running: overlayWin.visible
        z: 0 
        
        ItemParticle {
            delegate: Rectangle {
                width: 15 * Math.random() + 5
                height: currentTheme.particleShape === "line" ? width * 3 : width
                radius: currentTheme.particleShape === "circle" ? width/2 : 0
                color: "white"
                opacity: 0.2
                rotation: currentTheme.particleShape === "square" ? Math.random() * 360 : 0
            }
            fade: true
        }

        Emitter {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: 100
            emitRate: 40
            lifeSpan: 4000
            lifeSpanVariation: 1000
            size: 20
            velocity: PointDirection {
                y: -150
                yVariation: 80
                xVariation: 30
            }
            acceleration: PointDirection {
                y: -30
            }
        }
    }

    // 3. 核心内容区 (Loader 动态加载不同主题)
    Item {
        id: contentCard
        width: 600
        height: 600
        anchors.centerIn: parent
        scale: 0.8
        opacity: 0
        z: 1 
        
        // 进场动画
        ParallelAnimation {
            id: mainEntranceAnim
            NumberAnimation {
                target: contentCard
                property: "scale"
                to: 1.0
                duration: 800
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: contentCard
                property: "opacity"
                to: 1.0
                duration: 500
            }
        }

        // --- 中心视觉加载器 (Switch between Circle, Hexagon, Radar, etc.) ---
        Loader {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -60
            sourceComponent: {
                switch(currentTheme.centerVisual) {
                    case "tech_hexagon": return compHexagon;
                    case "radar_scan": return compRadar;
                    case "energy_pulse": return compEnergy;
                    default: return compCircle;
                }
            }
        }

        // COMPONENT: 圆环 (Classic)
        Component {
            id: compCircle
            Item {
                width: 300
                height: 300
                
                // 脉动光环
                Rectangle {
                    anchors.centerIn: parent
                    width: 300
                    height: 300
                    radius: 150
                    color: "transparent"
                    border.color: "#ffffff"
                    border.width: 2
                    opacity: 0.3
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 1.0
                            to: 1.3
                            duration: 1200
                        }
                        NumberAnimation {
                            from: 1.3
                            to: 1.0
                            duration: 1200
                        }
                    }
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 0.6
                            to: 0.0
                            duration: 1200
                        }
                        NumberAnimation {
                            from: 0.0
                            to: 0.6
                            duration: 1200
                        }
                    }
                }
                // 实心圆背景
                Rectangle {
                    width: 220
                    height: 220
                    radius: 110
                    color: "#ffffff"
                    anchors.centerIn: parent
                    Text {
                        anchors.centerIn: parent
                        text: currentTheme.icon
                        font.pixelSize: 100
                    }
                }
                // 旋转虚线
                Item {
                    anchors.fill: parent
                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 10000
                    }
                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.strokeStyle = "rgba(255, 255, 255, 0.5)"
                            ctx.lineWidth = 2
                            ctx.setLineDash([15, 30]) // 虚线样式
                            ctx.beginPath()
                            ctx.arc(width/2, height/2, width/2-25, 0, 2*Math.PI)
                            ctx.stroke()
                        }
                    }
                }
            }
        }

        // COMPONENT: 六边形 (Tech)
        Component {
            id: compHexagon
            Item {
                width: 300
                height: 300
                
                // 旋转六边形 Canvas
                Canvas {
                    id: hexCanvas
                    anchors.fill: parent
                    property real rot: 0
                    RotationAnimation on rot {
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 10000
                    }
                    onRotChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        var r = width/2 - 20
                        var cx = width/2
                        var cy = height/2
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.6)"
                        ctx.lineWidth = 4
                        ctx.beginPath()
                        // 绘制六边形
                        for(var i=0; i<6; i++) {
                            var ang = (rot + i * 60) * Math.PI / 180
                            var x = cx + r * Math.cos(ang)
                            var y = cy + r * Math.sin(ang)
                            if(i==0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                        }
                        ctx.closePath()
                        ctx.stroke()
                    }
                }
                // 内部白色六边形背景
                Rectangle {
                    width: 180
                    height: 180
                    color: "white"
                    anchors.centerIn: parent
                    rotation: 45 // 菱形/方形替代简单六边形背景
                    Text {
                        anchors.centerIn: parent
                        text: currentTheme.icon
                        font.pixelSize: 80
                        rotation: -45
                    }
                }
            }
        }

        // COMPONENT: 雷达扫描 (Radar)
        Component {
            id: compRadar
            Item {
                width: 300
                height: 300
                // 扫描线动画
                Rectangle {
                    anchors.centerIn: parent
                    width: 300
                    height: 300
                    radius: 150
                    color: "transparent"
                    border.color: "#4Dffffff"
                    border.width: 2
                    
                    Rectangle {
                        width: 150
                        height: 300
                        color: "transparent"
                        anchors.right: parent.horizontalCenter
                        clip: true
                        Rectangle { // 扫描扇形
                            width: 300
                            height: 300
                            radius: 150
                            anchors.right: parent.right
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: 0.5
                                    color: "#80ffffff"
                                }
                            }
                            RotationAnimation on rotation {
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 2000
                            }
                        }
                    }
                }
                // 中心
                Rectangle {
                    width: 200
                    height: 200
                    radius: 100
                    color: "white"
                    anchors.centerIn: parent
                    Text {
                        anchors.centerIn: parent
                        text: currentTheme.icon
                        font.pixelSize: 90
                    }
                }
            }
        }

        // COMPONENT: 能量球 (Energy)
        Component {
            id: compEnergy
            Item {
                width: 300
                height: 300
                // 多层发光圆
                Repeater {
                    model: 3
                    Rectangle {
                        anchors.centerIn: parent
                        width: 200 + index*40
                        height: width
                        radius: width/2
                        color: "transparent"
                        border.color: "white"
                        border.width: 2
                        opacity: 0.1 + (index * 0.1)
                        ScaleAnimator on scale {
                            from: 0.8
                            to: 1.1
                            duration: 1000 + index*500
                            loops: Animation.Infinite
                            easing.type: Easing.SineCurve
                        }
                    }
                }
                Rectangle {
                    width: 220
                    height: 220
                    radius: 110
                    color: "white"
                    anchors.centerIn: parent
                    // 内部发光
                    layer.enabled: true
                    Text {
                        anchors.centerIn: parent
                        text: currentTheme.icon
                        font.pixelSize: 100
                    }
                }
            }
        }

        // 文字区 (始终位于视觉组件下方)
        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 160 // 向下偏移
            spacing: 15
            
            Text {
                text: "该起来活动了!"
                color: "white"
                font.pixelSize: 48
                font.bold: true
                font.letterSpacing: 4
                font.family: "Microsoft YaHei UI" // 中文友好字体
                anchors.horizontalCenter: parent.horizontalCenter
                style: Text.Outline
                styleColor: currentTheme.textColor
            }
            
            Text {
                id: quoteText
                text: currentTheme.quote || "身体是革命的本钱，起来充充电吧 ⚡"
                color: "#E0F2F1"
                font.pixelSize: 22
                font.letterSpacing: 1
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    
    // 4. 底部按钮区
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 50
        z: 100 

        // 按钮 1: 完成运动
        Button {
            id: finishBtn
            width: 220
            height: 70
            topPadding: 0
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0
            
            // 禁用状态下不响应点击（防止误触），但在强制运动倒计时期间保持 enabled 以显示倒计时状态
            // 只有当 isForcedLocked 为 false 时才是真正的 "完成" 按钮
            
            background: Rectangle {
                id: btnBg
                // 正常状态：白色；锁定状态：半透明背景
                color: overlayWin.isForcedLocked ? "#33ffffff" : (parent.down ? "#dddddd" : (parent.hovered ? "#f0f0f0" : "#ffffff"))
                radius: 35
                
                // === 强制运动倒计时进度条 (美化版) ===
                // 使用 OpacityMask 确保进度条严格贴合圆角
                Item {
                    anchors.fill: parent
                    visible: overlayWin.isForcedLocked
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: btnBg.width
                            height: btnBg.height
                            radius: btnBg.radius
                            visible: false
                        }
                    }

                    Rectangle {
                        height: parent.height
                        // 进度计算：(总时长 - 剩余) / 总时长
                        width: overlayWin.totalForcedDuration > 0 ? 
                               parent.width * (1.0 - overlayWin.remainingForcedSeconds / overlayWin.totalForcedDuration) : 0
                        
                        // 使用原本按钮的白色作为进度条颜色
                        color: "#ffffff"
                        opacity: 0.9 // 稍微一点点透，更有质感

                        // 平滑动画
                        Behavior on width { NumberAnimation { duration: 100 } }
                    }
                }
                
                // 按钮阴影 (仅在非锁定状态显示)
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 5
                    z: -1
                    radius: 35
                    color: "black"
                    opacity: overlayWin.isForcedLocked ? 0 : 0.3
                    visible: !overlayWin.isForcedLocked
                }
                
                // 悬停光晕 (仅在非锁定状态显示)
                Rectangle {
                    anchors.fill: parent
                    radius: 35
                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                    opacity: (!overlayWin.isForcedLocked && parent.parent.hovered) ? 0.5 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                
                // 锁定状态下的边框
                border.color: overlayWin.isForcedLocked ? "#44ffffff" : "transparent"
                border.width: overlayWin.isForcedLocked ? 1 : 0
            }
            
            contentItem: Item {
                anchors.fill: parent
                
                // 1. 正常状态内容
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: !overlayWin.isForcedLocked
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    
                    Text {
                        text: "✅"
                        font.pixelSize: 22
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "完成运动"
                        color: currentTheme.textColor
                        font.pixelSize: 22
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                // 2. 锁定倒计时内容 (仅显示 "完成运动"，但颜色可能需要适配)
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: overlayWin.isForcedLocked
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    
                    Text {
                        text: "⏳" 
                        color: "white" // 在深色背景/白色进度条上，白色可能看不清，这里需要巧妙处理
                        // 实际上，因为进度条是白色，文字如果是黑色最好。
                        // 如果进度条没满，背景是半透白，文字也是白色？
                        // 简单点，用黑色或深色，因为背景最终会变白
                        // 或者始终保持 "完成运动" 的样式，只是不可点击
                        // 用户说：不要显示"加油..."，进度条颜色沿用按钮原本颜色(白)。
                        // 那么文字应该沿用按钮原本文字颜色(黑/深色)。
                        
                        font.pixelSize: 22
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "完成运动"
                        color: currentTheme.textColor // 保持与正常状态一致
                        font.pixelSize: 22
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            
            onClicked: {
                // 1. 强制运动拦截逻辑 (双重保险，虽然 UI 上已经提示了)
                if (overlayWin.isForcedLocked) {
                    var msg = "加油！还需坚持 " + overlayWin.remainingForcedSeconds + " 秒才能完成哦"
                    showToast(msg)
                    return
                }

                // 2. 计算时长 (前端计算，不依赖后端信号，确保响应速度)
                var now = new Date()
                var durationSeconds = 0
                if(overlayWin.showTime) {
                    durationSeconds = Math.floor((now - overlayWin.showTime) / 1000)
                }
                
                // 2. 记录数据到后端并获取最新统计
                timerEngine.recordExercise(durationSeconds)
                overlayWin.todayTotalSeconds = timerEngine.getTodayExerciseSeconds()
                overlayWin.weeklyStats = timerEngine.getWeeklyExerciseStats()
                overlayWin.todaySessions = timerEngine.getTodaySessions() // 获取最新会话列表

                // 3. 格式化文本
                var mins = Math.floor(durationSeconds / 60)
                var secs = durationSeconds % 60
                var timeStr = ""
                if(mins > 0) timeStr += mins + " 分 "
                timeStr += secs + " 秒"
                
                overlayWin.feedbackText = "本次运动: " + timeStr
                
                // 格式化时间段: HH:mm - HH:mm
                var startStr = Qt.formatTime(overlayWin.showTime, "HH:mm")
                var endStr = Qt.formatTime(now, "HH:mm")
                overlayWin.sessionTimeRange = startStr + " - " + endStr
                
                // 4. 显示反馈并准备关闭
                // closeTimer.restart() // 已移除，通过 feedbackLayer 可见性自动触发倒计时
            }
        }
        
        // 按钮 2: 稍后提醒
        Button {
            width: 220
            height: 70
            topPadding: 0
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0
            
            // 当强制锁定时，视觉上变暗
            opacity: overlayWin.isForcedLocked ? 0.5 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            background: Rectangle {
                color: parent.down ? "#55000000" : (parent.hovered ? "#44000000" : "#33000000")
                radius: 35
                // 锁定时隐藏边框高亮
                border.color: (!overlayWin.isForcedLocked && parent.hovered) ? "white" : "#e0e0e0"
                border.width: (!overlayWin.isForcedLocked && parent.hovered) ? 3 : 2
                Behavior on border.width { NumberAnimation { duration: 100 } }
            }
            
            contentItem: Item {
                anchors.fill: parent
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: overlayWin.isForcedLocked ? "🔒" : "💤"
                        color: "#ffffff"
                        font.pixelSize: 22
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "稍后提醒"
                        color: "#ffffff"
                        font.pixelSize: 22
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            
            onClicked: {
                // 使用统一的锁定状态判断
                if (overlayWin.isForcedLocked) {
                    var msg = "强制运动模式下无法推迟哦，请坚持完成！"
                    showToast(msg)
                    return
                }
                overlayWin.snoozeRequested()
            }
        }
    }

    // ========================================================================
    // Toast Notification (Forced Exercise Warning)
    // ========================================================================
    Rectangle {
        id: toast
        // Adaptive width: Padding + Indicator + Spacing + Text + Padding
        width: toastText.implicitWidth + 50 
        height: 40
        radius: 20
        
        // Visual Style matching app theme (Glassmorphism / Dark Blue)
        color: "#E61B2A4E" // High opacity dark blue for better readability
        border.color: "#33ffffff"
        border.width: 1
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 180 // Initial position for animation
        
        z: 2000 // Topmost
        
        // Initial state
        opacity: 0
        visible: opacity > 0
        scale: 0.9

        // Icon/Indicator
        Rectangle {
            id: indicator
            width: 8
            height: 8
            radius: 4
            color: "#FF4444" // Red for warning
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            
            // Breathing animation for the indicator
            SequentialAnimation on opacity {
                running: toast.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 800 }
                NumberAnimation { to: 1.0; duration: 800 }
            }
        }

        Text {
            id: toastText
            anchors.left: indicator.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
            font.pixelSize: 14
            font.bold: true
            font.family: "Microsoft YaHei UI"
        }

        // Show Animation
        ParallelAnimation {
            id: toastShowAnim
            NumberAnimation { target: toast; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { target: toast; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack }
            NumberAnimation { target: toast; property: "anchors.bottomMargin"; to: 200; duration: 200; easing.type: Easing.OutQuad }
        }

        // Hide Animation
        NumberAnimation {
            id: toastHideAnim
            target: toast
            property: "opacity"
            to: 0
            duration: 300
            easing.type: Easing.InQuad
        }

        // Auto-hide Timer
        Timer {
            id: toastTimer
            interval: 3500 // Slightly longer for reading
            onTriggered: toastHideAnim.start()
        }
    }

    function showToast(message) {
        toastText.text = message
        // Reset properties for animation
        toast.anchors.bottomMargin = 180
        toastShowAnim.restart()
        toastTimer.restart()
    }
}
