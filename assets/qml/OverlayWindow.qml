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
            showTime = new Date()
            showFullScreen() // 确保全屏
            raise()          // 提升窗口层级
            // 重启动画
            mainEntranceAnim.restart()
            bgAnim.restart()
        } else {
            // 隐藏时重置状态
            feedbackText = ""
        }
    }

    // 兼容旧代码的别名，避免修改大量内部引用
    property alias currentTheme: overlayWin.themeData

    // -------------------------------------------------------------------------
    // UI 实现
    // -------------------------------------------------------------------------

    // 0. 反馈状态
    property string feedbackText: ""
    property var showTime: null

    // 自动关闭计时器
    // 当显示反馈结果（如"本次运动完成"）后，3秒后自动关闭窗口
    Timer {
        id: closeTimer
        interval: 3000
        onTriggered: {
            overlayWin.reminderFinished()
        }
    }

    // ========================================================================
    // 反馈遮罩层 (Feedback Layer)
    // ========================================================================
    // 当用户完成运动后显示的结算界面
    Rectangle {
        id: feedbackLayer
        anchors.fill: parent
        color: "transparent"
        visible: overlayWin.feedbackText !== "" // 只有有反馈文本时才显示
        z: 999 // 确保最顶层

        // 1. 背景模糊与变暗
        Rectangle {
            anchors.fill: parent
            color: "#CC000510" // 80% 不透明度的深色背景
            opacity: feedbackLayer.visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 500 } }
        }

        MouseArea { anchors.fill: parent } // 阻止交互，强制观看结算动画

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
            width: 420
            height: 520
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
                    xScale: feedbackLayer.visible ? 1.0 : 0.8
                    yScale: feedbackLayer.visible ? 1.0 : 0.8
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
                
                // B. 文字信息
                Column {
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        text: "本次运动完成"
                        color: "#88ffffff"
                        font.pixelSize: 12
                        font.letterSpacing: 3
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0
                        SequentialAnimation on opacity {
                            running: feedbackLayer.visible
                            PauseAnimation { duration: 500 }
                            NumberAnimation { to: 1; duration: 500 }
                        }
                    }
                    
                    Text {
                        id: timeTextDisplay // 添加 ID 以供动画引用
                        // 从 "本次运动时长: XX 分 XX 秒" 解析出 "XX:XX" 或保留原样但大号显示
                        // 这里我们做个简单的解析优化，让数字更大
                        property string rawText: overlayWin.feedbackText
                        text: rawText.replace("本次运动时长: ", "")
                        
                        color: "white"
                        font.pixelSize: 48
                        font.weight: Font.Bold
                        font.family: "Segoe UI" // Windows 友好字体
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        layer.enabled: true
                        layer.effect: DropShadow {
                            horizontalOffset: 0; verticalOffset: 0
                            radius: 10; samples: 17; color: currentTheme.gradientEnd
                        }
                        
                        scale: 0.8
                        opacity: 0
                        SequentialAnimation {
                            running: feedbackLayer.visible
                            PauseAnimation { duration: 600 }
                            ParallelAnimation {
                                NumberAnimation { target: timeTextDisplay; property: "opacity"; to: 1; duration: 500 }
                                NumberAnimation { target: timeTextDisplay; property: "scale"; to: 1; duration: 500; easing.type: Easing.OutBack }
                            }
                        }
                    }
                }
                
                // C. 底部倒计时条
                Item {
                    width: 300
                    height: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        text: "正在恢复工作模式..."
                        color: "#66ffffff"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }
                    
                    // 进度条
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width * (3000 - closeTimerCountdown.elapsed) / 3000
                        height: 2
                        color: currentTheme.gradientEnd
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        // 倒计时动画辅助属性
                        Item {
                            id: closeTimerCountdown
                            property int elapsed: 0
                            NumberAnimation on elapsed {
                                running: feedbackLayer.visible
                                from: 0; to: 3000; duration: 3000
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
        
        // 背景呼吸效果
        SequentialAnimation on opacity {
            id: bgAnim
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.9
                to: 1.0
                duration: 3000
            }
            NumberAnimation {
                from: 1.0
                to: 0.9
                duration: 3000
            }
        }
    }

    // 2. 粒子系统 (Ambient Particles)
    ParticleSystem {
        id: particles
        anchors.fill: parent
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
            width: 220
            height: 70
            
            background: Rectangle {
                color: parent.down ? "#dddddd" : (parent.hovered ? "#f0f0f0" : "#ffffff")
                radius: 35
                
                // 按钮阴影
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 5
                    z: -1
                    radius: 35
                    color: "black"
                    opacity: 0.3
                }
                
                // 悬停光晕
                Rectangle {
                    anchors.fill: parent
                    radius: 35
                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                    opacity: parent.parent.hovered ? 0.5 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
            
            contentItem: Text {
                text: "✅ 完成运动"
                color: currentTheme.textColor
                font.pixelSize: 22
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                // 1. 计算时长 (前端计算，不依赖后端信号，确保响应速度)
                var now = new Date()
                var durationSeconds = 0
                if(overlayWin.showTime) {
                    durationSeconds = Math.floor((now - overlayWin.showTime) / 1000)
                }
                
                var mins = Math.floor(durationSeconds / 60)
                var secs = durationSeconds % 60
                var timeStr = ""
                if(mins > 0) timeStr += mins + " 分 "
                timeStr += secs + " 秒"
                
                overlayWin.feedbackText = "本次运动时长: " + timeStr
                
                // 2. 显示反馈并准备关闭
                closeTimer.restart()
                
                // 3. 通知后端重置计时器
                timerEngine.startWork()
            }
        }
        
        // 按钮 2: 稍后提醒
        Button {
            width: 220
            height: 70
            
            background: Rectangle {
                color: parent.down ? "#55000000" : (parent.hovered ? "#44000000" : "#33000000")
                radius: 35
                border.color: parent.hovered ? "white" : "#e0e0e0"
                border.width: parent.hovered ? 3 : 2
                Behavior on border.width { NumberAnimation { duration: 100 } }
            }
            
            contentItem: Text {
                text: "💤 稍后提醒"
                color: "#ffffff"
                font.pixelSize: 22
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                overlayWin.snoozeRequested()
            }
        }
    }
}
