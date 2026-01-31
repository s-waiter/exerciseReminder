import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Particles 2.0 // 引入粒子系统
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
    
    // 启动时静默检查更新
    Component.onCompleted: updateManager.checkForUpdates(true)
    
    // 动态调整窗口大小：
    // isPinned (迷你模式): 120x120
    // Normal (正常模式): 280x420 (恢复到用户觉得舒适的尺寸)
    width: isPinned ? 120 : 280
    height: isPinned ? 120 : 420
    visible: true
    title: "DeskCare"
    color: "transparent" // 窗口背景完全透明，由内部 Rectangle 绘制实际背景
    
    // ========================================================================
    // 窗口标志 (Window Flags)
    // ========================================================================
    // Qt.FramelessWindowHint: 去除操作系统的标题栏和边框，完全自定义 UI。
    // Qt.Window: 这是一个顶级窗口。
    property bool isPinned: false
    // 交互点坐标，用于粒子吸引效果
    property point interactionPoint: Qt.point(width/2, height/2)
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
        // 1. 水平方向：Normal宽280(中心140) -> Mini宽120(中心60)。差值 80。
        //    切换到 Mini (变窄)，内容相对窗口左移了，为了保持视觉位置，窗口需右移 80。
        // 2. 垂直方向：Normal TopMargin 60 -> Mini TopMargin 10。
        //    Normal CircleCenterY = 60 + 150/2 = 135
        //    Mini CircleCenterY = 10 + 100/2 = 60
        //    差值 135 - 60 = 75。
        //    切换到 Mini (上移)，内容相对窗口上移了，为了保持视觉位置，窗口需下移 75。
        
        if (isPinned) {
            mainWindow.x += 80
            mainWindow.y += 75
        } else {
            mainWindow.x -= 80
            mainWindow.y -= 75
        }
    }
    
    // ========================================================================
    // 状态属性
    // ========================================================================
    property bool isChecking: false
    // 监听 UpdateManager 信号，重置检查状态
    Connections {
        target: updateManager
        function onUpdateAvailable(version, changelog, url) { 
            if (mainWindow.isChecking) {
                updateDialog.open()
            }
            mainWindow.isChecking = false 
        }
        function onNoUpdateAvailable() { 
            if (mainWindow.isChecking) {
                toast.show("当前已是最新版本", "#00FF7F")
            }
            mainWindow.isChecking = false 
        }
        function onUpdateError(msg) { 
            if (mainWindow.isChecking) {
                toast.show(msg, "#FF4444")
            }
            mainWindow.isChecking = false 
        }
    }

    // 连接 TrayIcon 信号
    Connections {
        target: trayIcon
        function onShowMainWindowRequested() {
            // 迷你模式下(isPinned)不做任何动作，因为悬浮球已经在桌面置顶
            // 正常模式下直接显示主界面
            if (!mainWindow.isPinned) {
                mainWindow.show()
                mainWindow.raise()
                mainWindow.requestActivate()
            }
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
            // 更新交互点
            mainWindow.interactionPoint = Qt.point(mouseX, mouseY)

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
                width: isPinned ? 160 : 220
                height: isPinned ? 160 : 220
                radius: width / 2
                color: mainWindow.themeColor
                opacity: 0.05
                x: isPinned ? (parent.width - width) / 2 : -40
                y: isPinned ? (parent.height - height) / 2 : -40
                
                // 尺寸平滑过渡
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                
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
            height: isPinned ? 20 : 40
            anchors.top: parent.top
            z: 10 
            
            // 迷你模式下自动隐藏/显示：鼠标移入时显示，移出隐藏
            opacity: isPinned ? (windowMouseArea.containsMouse ? 1.0 : 0.0) : 1.0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Column {
                anchors.centerIn: parent
                spacing: 0
                visible: !mainWindow.isPinned // 迷你模式不显示标题文字

                Text {
                    text: "DeskCare"
                    color: "#FFFFFF"
                    opacity: 0.8 // 稍微提升主标题可见度
                    font.family: "Segoe UI"
                    font.pixelSize: 15 // 字号恢复一点
                    font.bold: true
                    font.letterSpacing: 1.5 // 增加主标题字间距，拉宽整体
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "久坐提醒助手"
                    color: "#FFFFFF"
                    opacity: 0.75 // 提高不透明度，确保清晰可见
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 10 // 稍微调大字号
                    font.letterSpacing: 0 // 保持紧凑
                    font.bold: false 
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // 按钮容器，用于在不同模式下调整位置
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 15
                anchors.top: parent.top
                anchors.topMargin: 10
                spacing: 5
                
                // 设置按钮 (已移除，版本号移至右下角)
                /*
                Button {
                    id: settingsBtn
                    width: 30
                    height: 30
                    visible: !mainWindow.isPinned // 迷你模式下隐藏
                    background: Rectangle { color: "transparent" }
                    contentItem: Text {
                        text: "⚙" // Gear icon
                        color: "white"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: settingsPopup.open()
                }
                */

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
        // 4. 氛围粒子系统：Zen Mode
        // ========================================================================
        // 粒子行为保持恒定的平静状态，旨在提供一种宁静的陪伴感，
        // 而不是通过紧迫感来催促用户。
        ParticleSystem {
            id: emotionParticles
            anchors.fill: parent
            // 始终运行，不受暂停状态影响
            running: true
            
            // 始终保持平静的科技蓝/青色调，或者跟随主题色
            property color particleColor: mainWindow.themeColor
            
            // 粒子画笔
            ItemParticle {
                delegate: Rectangle {
                    width: Math.random() * 3 + 1 // 1-4px
                    height: width
                    radius: width / 2
                    color: emotionParticles.particleColor
                    opacity: 0.3 // 稍微降低不透明度，更加朦胧
                }
                fade: true
            }

            // 发射器
            Emitter {
                anchors.fill: parent
                // 恒定低发射率，营造稀疏、空灵感
                emitRate: 8 
                lifeSpan: 4000 // 延长生命周期，让粒子飘得更久
                size: 4
                sizeVariation: 2
                
                velocity: AngleDirection {
                    angleVariation: 360
                    // 恒定低速，如水中浮游生物般缓慢
                    magnitude: 20 
                    magnitudeVariation: 10
                }
            }
            
            // 扰动场：轻微的气流感
            Wander {
                anchors.fill: parent
                xVariance: 30 
                yVariance: 30 
                pace: 100 
            }

            // 鼠标吸引器：仅在迷你模式下生效，让粒子向鼠标聚集
            Attractor {
                id: mouseAttractor
                anchors.fill: parent
                pointX: mainWindow.interactionPoint.x
                pointY: mainWindow.interactionPoint.y
                strength: 0 // 默认无吸引力
                
                // 当鼠标悬停在任意区域时触发 (包含中心圆环和边缘窗口)
                states: State {
                    when: isPinned && (windowMouseArea.containsMouse || centerMouseArea.containsMouse)
                    PropertyChanges { target: mouseAttractor; strength: 5.0 } 
                }
                
                transitions: Transition {
                    NumberAnimation { property: "strength"; duration: 1000; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ========================================================================
        // 核心内容区
        // ========================================================================
        
        // 1. 环形进度条 + 时间显示 (独立于 Column，固定位置)
        Item {
            id: circleItem
            // 动态调整尺寸：Normal 150 -> Mini 100
            width: isPinned ? 100 : 150
            height: isPinned ? 100 : 150
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            // Normal模式下下移 60px 以避开标题栏，Mini模式下仅保留 10px 边距居中
            // 配合 onIsPinnedChanged 中的窗口坐标补偿，实现视觉位置静止
            anchors.topMargin: isPinned ? 10 : 60
            
            // 关键：尺寸和 Margin 动画必须与窗口几何动画完全同步 (duration/easing 一致)
            // 这样 WindowY(t) + TopMargin(t) = Constant，从而消除视觉抖动
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            
            // 外圈轨道
            Rectangle {
                anchors.fill: parent
                radius: width/2
                // 迷你模式下添加深色背景以增强对比度，解决文字看不清的问题
                color: isPinned ? "#99000000" : "transparent"
                border.color: "#33ffffff"
                border.width: 4
                
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            
            // === 迷你模式下的呼吸光效 (背景层) ===
            // 移出 Canvas layer，作为独立背景存在，避免覆盖进度条
            RectangularGlow {
                id: breathingGlow
                anchors.fill: parent
                glowRadius: 10
                spread: 0.1 // 降低扩散度，避免太亮
                // 跟随 Canvas 的动态颜色
                color: progressCanvas.drawColor 
                cornerRadius: width/2
                visible: isPinned && timerEngine.statusText === "工作中"
                opacity: 0.2 // 降低初始不透明度，防止过曝
                
                // 呼吸动画
                SequentialAnimation on opacity {
                    running: breathingGlow.visible
                    loops: Animation.Infinite
                    PropertyAnimation { to: 0.5; duration: 2000; easing.type: Easing.InOutSine }
                    PropertyAnimation { to: 0.2; duration: 2000; easing.type: Easing.InOutSine }
                }
                
                // 悬停时增强光效
                states: State {
                    when: centerMouseArea.containsMouse
                    PropertyChanges { target: breathingGlow; spread: 0.4; opacity: 0.6 }
                }
                transitions: Transition {
                    NumberAnimation { duration: 200 }
                }
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
                
                // 动态颜色逻辑 (仅迷你模式生效)
                property color drawColor: {
                    if (!isPinned) return mainWindow.themeColor
                    
                    // 根据剩余时间百分比改变颜色
                    // > 80%: 科技蓝 (初始)
                    // 50% - 80%: 清新绿 (平稳)
                    // 20% - 50%: 警示黄 (过半)
                    // < 20%: 紧急红 (即将结束)
                    if (progress > 0.8) return "#00d2ff" 
                    if (progress > 0.5) return "#00ff88"
                    if (progress > 0.2) return "#ffbf00"
                    return "#ff3b30"
                }
                
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
                    ctx.lineWidth = isPinned ? 6 : 6; // 迷你模式下稍微加粗一点
                    ctx.lineCap = "round"; // 圆头线帽
                    
                    if (isPinned) {
                        // === 迷你模式：锥形渐变 (拖尾效果) ===
                        // ConicalGradient 需要中心点，但在 HTML5 Canvas API (Qt实现) 中，createConicalGradient 是标准方法
                        // 注意：Qt Quick Canvas 的渐变坐标系可能与标准略有不同，通常 ConicalGradient 以圆心为原点
                        // startAngle 应该跟随进度动态旋转，保持高亮头部始终在最前
                        
                        // 由于 Canvas 的 ConicalGradient 比较难以完美控制角度 (特别是动态变化时)，
                        // 这里我们使用一种模拟技巧：使用 createLinearGradient 但调整控制点方向，
                        // 或者分段绘制。但为了性能和效果平衡，我们优化 LinearGradient 的方向。
                        
                        // 更好的方案：计算当前进度的切线方向，设置 LinearGradient
                        // 这样可以让渐变始终沿着切线方向，模拟头部亮尾部暗
                        var angle = Math.PI * 2 * progress;
                        var startX = centerX + radius * Math.cos(angle);
                        var startY = centerY + radius * Math.sin(angle);
                        // 渐变终点设在圆环的某个后方位置，模拟拖尾
                        var endX = centerX + radius * Math.cos(angle - 1); 
                        var endY = centerY + radius * Math.sin(angle - 1);
                        
                        // 但简单的 LinearGradient 很难沿着圆弧弯曲。
                        // 如果要完美的拖尾，通常需要使用 ShaderEffect 或者大量的分段绘制。
                        // 这里我们退一步，使用一种更稳健的 LinearGradient 策略，
                        // 让它看起来头部最亮，整体均匀过渡。
                        
                        // 之前的 LinearGradient 是 (0,0) 到 (width,height)，这在圆环旋转时效果不稳定。
                        // 我们改为始终相对于进度条末端的高亮。
                        
                        var gradient = ctx.createLinearGradient(0, 0, width, height);
                        gradient.addColorStop(0, drawColor); 
                        gradient.addColorStop(1, Qt.darker(drawColor, 2.0)); // 尾部更暗，增强立体感
                        ctx.strokeStyle = gradient;
                        
                    } else {
                        // 正常模式：保持原有逻辑
                        var gradient = ctx.createLinearGradient(0, 0, width, height);
                        gradient.addColorStop(0, drawColor); // 主色
                        gradient.addColorStop(1, "#3a7bd5");
                        if (drawColor == "#ffbf00") gradient.addColorStop(1, "#ff9100");
                        else if (drawColor == "#00ff88") gradient.addColorStop(1, "#00bfa5");
                        ctx.strokeStyle = gradient;
                    }
                    
                    ctx.stroke();
                }
            }
            
            // === 迷你模式下的触感“流光” (Rim Light) ===
            // 这是一个跟随进度条末端移动的高亮光点
            Item {
                id: rimLightContainer
                anchors.fill: parent
                visible: isPinned && timerEngine.statusText === "工作中" && progressCanvas.progress > 0
                rotation: -90 // 配合 Canvas 的旋转
                
                // 光点本体
                Rectangle {
                    id: rimLight
                    width: 2.5 // 缩小核心尺寸，极致精致，只保留光的质感
                    height: 2.5
                    radius: 1.25
                    color: "white" // 纯白核心，最亮
                    
                    // 计算光点位置
                    // 极坐标转直角坐标: x = r * cos(theta), y = r * sin(theta)
                    // 注意：这里的坐标系原点是 parent 的中心
                    readonly property double orbitRadius: parent.width / 2 - 4 // 与 Canvas 半径一致
                    readonly property double angle: progressCanvas.progress * 2 * Math.PI
                    
                    // 微调位置：由于 lineCap="round"，进度条末端会多出一个半圆。
                    // 为了让光点刚好位于这个半圆的圆心（即视觉上的最前端），
                    // 我们不需要额外的角度偏移，因为 arc 的终点正是圆心位置。
                    // 之前的错位感主要是因为光点太大 (8px) 覆盖了圆头。
                    // 现在缩小到 4px 后，应该完美居中于圆头内。
                    
                    x: parent.width/2 + orbitRadius * Math.cos(angle) - width/2
                    y: parent.height/2 + orbitRadius * Math.sin(angle) - height/2
                    
                    // 强烈的辉光效果
                    layer.enabled: true
                    layer.effect: RectangularGlow {
                        id: rimLightGlow
                        glowRadius: 12 // 基础光晕
                        spread: 0.2 // 进一步降低扩散度，让光晕更弥散、通透
                        color: progressCanvas.drawColor // 跟随主色调
                        cornerRadius: 12 // 匹配 glowRadius 确保圆形光晕
                        opacity: 0.9 // 保持高透明度，增强光的通透感
                        
                        // 动态呼吸：模拟脉冲能量
                        SequentialAnimation on glowRadius {
                            running: rimLightContainer.visible
                            loops: Animation.Infinite
                            PropertyAnimation { to: 15; duration: 1000; easing.type: Easing.InOutSine }
                            PropertyAnimation { to: 12; duration: 1000; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
            
            // 状态容器：统一管理倒计时和透视信息的切换
            Item {
                id: infoCenterContainer
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                
                // 1. 默认状态：倒计时 (Countdown State)
                Item {
                    id: countdownState
                    anchors.fill: parent
                    
                    // 当不在迷你模式下悬停时显示
                    property bool active: !(isPinned && centerMouseArea.containsMouse)
                    
                    opacity: active ? 1.0 : 0.0
                    scale: active ? 1.0 : 0.8 // 退出时缩小，营造空间纵深感
                    
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Text {
                            id: countdownText
                            // 使用 Math.floor 取整
                            property int mins: Math.floor(timerEngine.remainingSeconds / 60)
                            property int secs: timerEngine.remainingSeconds % 60
                            // 补零格式化: 9:5 -> 09:05
                            text: (mins < 10 ? "0"+mins : mins) + ":" + (secs < 10 ? "0"+secs : secs)
                            color: "#ffffff"
                            font.pixelSize: isPinned ? 28 : 34 // 迷你模式下字体稍微加大，因为去掉了下面的文字
                            font.family: "Segoe UI Light" // 细体字更有科技感
                            font.weight: Font.Light
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            Behavior on font.pixelSize { NumberAnimation { duration: 300 } }
                        }
                        
                        Text {
                            text: timerEngine.statusText
                            color: mainWindow.themeColor
                            font.pixelSize: isPinned ? 10 : 12 // 动态字体大小
                            font.bold: true
                            font.family: "Microsoft YaHei UI"
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.8
                            visible: !isPinned // 迷你模式下隐藏状态文字，让界面更清爽，只留数字
                            
                            Behavior on font.pixelSize { NumberAnimation { duration: 300 } }
                        }

                        // 预计结束时间 (ETA) - 正常模式下显示
                        Text {
                            text: "预计 " + timerEngine.estimatedFinishTime + " 休息"
                            color: "#8899A6" // 弱化显示
                            font.pixelSize: 12
                            font.family: "Microsoft YaHei UI"
                            // 在迷你模式下隐藏，避免遮挡和拥挤，保持界面清爽
                            // 修改：使用 opacity 代替 visible 控制显示，避免 layout 抖动
                            visible: !isPinned
                            opacity: timerEngine.statusText === "工作中" ? 1.0 : 0.0
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // 2. 透视状态：预计休息时间 (Smart Peek State)
                Item {
                    id: peekState
                    anchors.fill: parent
                    
                    // 仅在迷你模式且悬停时显示
                    property bool active: isPinned && centerMouseArea.containsMouse
                    
                    opacity: active ? 1.0 : 0.0
                    scale: active ? 1.0 : 1.1 // 进入时从 1.1 缩小到 1.0，营造浮现聚焦感
                    visible: opacity > 0 // 优化性能
                    
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 0 // 紧凑布局
                        
                        // Hero: 时间
                        Text {
                            text: timerEngine.estimatedFinishTime
                            color: "#ffffff" // 纯白高亮
                            font.pixelSize: 24
                            font.family: "Segoe UI"
                            font.styleName: "Semibold" // 确保数字清晰有力
                            font.weight: Font.DemiBold
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        // Label: 说明
                        Text {
                            text: "预计休息"
                            color: mainWindow.themeColor // 跟随动态主题色
                            font.pixelSize: 10
                            font.family: "Microsoft YaHei UI" // 强制使用微软雅黑，拒绝宋体
                            font.bold: true
                            font.letterSpacing: 2 // 增加字间距，提升精致感
                            opacity: 0.9
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // 交互层：点击暂停/继续，双击切换模式，三击立即休息
            MouseArea {
                id: centerMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true // 开启悬停以显示详细 ETA
                
                // 支持拖拽窗口 (即使在圆环上也能拖拽)
                property point clickPos
                property bool isDrag: false
                
                // 三击检测相关属性
                property int clickCount: 0
                
                // 1. 点击计数重置计时器 (500ms 无操作则重置计数)
                Timer {
                    id: clickCountResetTimer
                    interval: 500
                    onTriggered: centerMouseArea.clickCount = 0
                }
                
                // 2. 双击动作延迟计时器 (用于等待可能的第三次点击)
                Timer {
                    id: doubleClickActionTimer
                    interval: 250 // 延迟 250ms 执行双击动作
                    repeat: false
                    onTriggered: mainWindow.isPinned = !mainWindow.isPinned
                }
                
                // 3. 三击动作延迟计时器 (用于等待可能的第四次点击)
                Timer {
                    id: tripleClickActionTimer
                    interval: 250 // 延迟 250ms 执行三击动作
                    repeat: false
                    onTriggered: {
                        // 触发立即休息
                        themeController.generateRandomTheme()
                        isReminderActive = true
                    }
                }
                
                onPressed: {
                    clickPos = Qt.point(mouseX, mouseY)
                    isDrag = false
                    // lastPos 用于计算位移增量
                    lastPos = Qt.point(mouseX, mouseY)
                    
                    // === 多击检测逻辑 ===
                    clickCount++
                    clickCountResetTimer.restart() // 每次点击刷新重置计时器
                    
                    if (clickCount === 3) {
                        // 检测到三击：
                        // 1. 阻止即将发生的双击动作 (切换模式)
                        doubleClickActionTimer.stop()
                        
                        // 2. 启动三击延迟，等待可能的第四击
                        tripleClickActionTimer.start()
                        
                        // 注意：此处不立即重置 clickCount，以便 onClicked 中能检测到 clickCount >= 3
                    } else if (clickCount === 4) {
                        // 检测到四击：
                        // 1. 阻止三击动作
                        tripleClickActionTimer.stop()
                        
                        // 2. 触发午休模式
                        timerEngine.startNap()
                    }
                }
                
                property point lastPos
                onPositionChanged: {
                    // 更新交互点 (映射到窗口坐标)
                    var p = mapToItem(mainWindow.contentItem, mouseX, mouseY)
                    mainWindow.interactionPoint = p

                    if(pressed) {
                        var dx = mouseX - lastPos.x
                        var dy = mouseY - lastPos.y
                        
                        // 判断是否发生拖拽（设定 3 像素阈值），防止误触点击
                        if (!isDrag && (Math.abs(mouseX - clickPos.x) > 3 || Math.abs(mouseY - clickPos.y) > 3)) {
                            isDrag = true
                            clickCount = 0 // 发生拖拽，重置点击计数
                        }
                        
                        mainWindow.x += dx
                        mainWindow.y += dy
                    }
                }
                
                onClicked: {
                    // 只有在非拖拽且非三击序列中才触发暂停
                    // 如果 clickCount >= 3，说明是三击操作的一部分，不应触发单击逻辑
                    if (!isDrag && clickCount < 3) {
                        clickTimer.start()
                    }
                }
                
                onDoubleClicked: {
                    // 双击切换模式
                    if (!isDrag) {
                        clickTimer.stop() // 停止单击计时器，防止触发暂停
                        
                        // 不立即切换，而是启动延迟计时器，给三击留出判断时间
                        doubleClickActionTimer.start()
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
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: circleItem.bottom
            anchors.topMargin: 15
            visible: !mainWindow.isPinned
            height: visible ? implicitHeight : 0 // 确保隐藏时不占位
                
                // 间隔设置卡片
                Rectangle {
                    id: intervalCard
                    width: 60
                    height: 40
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
                        onClicked: hintAnim.restart()
                        // 支持鼠标滚轮直接调节时长
                        onWheel: {
                            var delta = wheel.angleDelta.y > 0 ? 1 : -1
                            var newVal = timerEngine.workDurationMinutes + delta
                            if (newVal >= 1 && newVal <= 120) {
                                timerEngine.workDurationMinutes = newVal
                            }
                        }
                    }

                    // 专用提示气泡
                    Rectangle {
                        id: wheelHint
                        // Width calculation: LeftPadding(12) + Indicator(8) + Spacing(8) + Text + RightPadding(12) = Text + 40
                        width: hintText.implicitWidth + 40 
                        height: 32
                        radius: 16
                        color: "#CC1B2A4E" // 半透明深色背景
                        border.color: "#33ffffff"
                        border.width: 1
                        anchors.top: parent.bottom
                        anchors.topMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: opacity > 0
                        opacity: 0
                        z: 100 // 确保显示在最上层

                        // 状态指示点
                        Rectangle {
                            id: hintIndicator
                            width: 8
                            height: 8
                            radius: 4
                            color: "#00d2ff"
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: hintText
                            text: "使用鼠标滚轮修改"
                            color: "white"
                            font.pixelSize: 12
                            font.family: "Microsoft YaHei"
                            anchors.left: hintIndicator.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        SequentialAnimation {
                            id: hintAnim
                            ParallelAnimation {
                                NumberAnimation { target: wheelHint; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutQuad }
                                NumberAnimation { target: wheelHint; property: "scale"; from: 0.9; to: 1; duration: 200; easing.type: Easing.OutBack }
                            }
                            PauseAnimation { duration: 2000 }
                            NumberAnimation { target: wheelHint; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InQuad }
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
                            font.pixelSize: 12
                            font.family: "Segoe UI"
                            height: 16 // 固定高度以对齐右侧开关
                            verticalAlignment: Text.AlignVCenter
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
                
                // 午休助眠卡片
                Rectangle {
                    id: napCard
                    width: 60
                    height: 40
                    color: "#1Affffff"
                    radius: 10
                    border.color: napMouseArea.containsMouse ? mainWindow.themeColor : "transparent"
                    border.width: 1
                    
                    scale: napMouseArea.containsMouse ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    MouseArea {
                        id: napMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: timerEngine.startNap()
                    }
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        
                        Text {
                            text: "☾" // Moon symbol
                            color: "white"
                            font.pixelSize: 14 // 保持与其他卡片内元素大小协调
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 16 // 与 intervalCard 的 text height 16 保持对齐
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        Text {
                            text: "午休助眠"
                            color: "#8899A6"
                            font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // 开机自启卡片 (极简 Switch 风格)
                Rectangle {
                    id: autoStartCard
                    width: 60
                    height: 40
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
                        spacing: 2 // 统一间距为 2
                        
                        // 自定义简约 Switch 控件
                        Rectangle {
                            width: 30 // 缩小宽度
                            height: 16 // 缩小高度至 16px 以匹配左侧文字
                            radius: 8
                            color: appConfig.autoStart ? mainWindow.themeColor : "#33ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            
                            // 滑块
                            Rectangle {
                                width: 12 // 缩小滑块
                                height: 12
                                radius: 6
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
                        font.pixelSize: 14
                    }
                    width: 100
                    height: 40
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

        // ========================================================================
        // 简易版本更新 (右下角)
        // ========================================================================
        
        // Update Logic Connections
        Connections {
            target: updateManager
            function onUpdateAvailable(version, changelog, url) {
                mainWindow.isChecking = false
                // 静默模式：不弹窗，只让图标闪烁 (通过 hasUpdate 属性自动处理)
                // toast.show("发现新版本 v" + version, "#00ff88") 
            }
            function onNoUpdateAvailable() {
                mainWindow.isChecking = false
                toast.show("当前已是最新版本", "#00d2ff") // 蓝色
            }
            function onUpdateError(error) {
                mainWindow.isChecking = false
                toast.show("检查失败: " + error, "#ff4444") // 红色
            }
        }

        // 自定义 Toast 提示组件 (位于右下角版本号上方)
        Rectangle {
            id: toast
            // Width calculation: LeftPadding(12) + Indicator(8) + Spacing(8) + Text + RightPadding(12) = Text + 40
            width: toastText.implicitWidth + 40 
            height: 32
            radius: 16
            color: "#CC1B2A4E" // 半透明深色背景
            border.color: "#33ffffff"
            border.width: 1
            anchors.bottom: versionContainer.top // 修正锚点：versionRow 已更名为 versionContainer
            anchors.bottomMargin: 4 // 缩短间距，使其紧挨着图标
            anchors.right: parent.right
            anchors.rightMargin: 12
            
            // 初始状态
            opacity: 0
            visible: opacity > 0
            scale: 0.9
            
            property alias message: toastText.text
            property alias accentColor: statusIndicator.color
            
            function show(msg, colorCode) {
                message = msg
                accentColor = colorCode || "#00d2ff"
                showAnim.restart()
                hideTimer.restart()
            }
            
            // 状态指示点
            Rectangle {
                id: statusIndicator
                width: 8
                height: 8
                radius: 4
                color: "#00d2ff"
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: toastText
                text: "提示信息"
                color: "white"
                font.pixelSize: 12
                font.family: "Microsoft YaHei"
                anchors.left: statusIndicator.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
            }
            
            // 动画
            ParallelAnimation {
                id: showAnim
                NumberAnimation { target: toast; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutQuad }
                NumberAnimation { target: toast; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack }
                NumberAnimation { target: toast; property: "anchors.bottomMargin"; from: 0; to: 4; duration: 200; easing.type: Easing.OutQuad }
            }
            
            NumberAnimation {
                id: hideAnim
                target: toast
                property: "opacity"
                to: 0
                duration: 300
                easing.type: Easing.InQuad
            }
            
            Timer {
                id: hideTimer
                interval: 3000
                onTriggered: hideAnim.start()
            }
        }

        // 右下角版本号容器
        Item {
            id: versionContainer
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            height: 20
            width: versionText.implicitWidth + refreshIconContainer.width
            visible: !isPinned 
            
            Text {
                id: versionText
                text: "v" + updateManager.currentVersion
                color: "#8899AA" 
                font.pixelSize: 10 
                font.family: "Microsoft YaHei"
                opacity: 0.8 
                anchors.right: refreshIconContainer.left
                anchors.rightMargin: 2 // 极小间距，精确控制
                anchors.verticalCenter: parent.verticalCenter
            }
            
            // 刷新图标容器
            Item {
                id: refreshIconContainer
                width: 14 // 紧贴字符宽度
                height: 20
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                // 视觉修正：向下偏移 1px
                anchors.verticalCenterOffset: 1 

                Text {
                    id: refreshIcon
                    text: "↻" 
                    // 优先级: 检查中 > 有更新 > 悬浮 > 默认
                    color: mainWindow.isChecking ? "#00d2ff" : 
                           (updateManager.hasUpdate ? "#00d2ff" :  // 有更新也用蓝色，仅靠呼吸区分
                           (mouseArea.containsMouse ? "#FFFFFF" : "#8899AA"))
                    
                    font.pixelSize: 13 
                    font.bold: true
                    
                    // 透明度呼吸特效
                    opacity: mainWindow.isChecking ? 1.0 : 
                             (updateManager.hasUpdate ? updateBreathingOpacity : 
                             (mouseArea.containsMouse ? 1.0 : 0.8))

                    anchors.centerIn: parent
                    
                    // 悬浮放大特效
                    scale: mouseArea.pressed ? 0.9 : (mouseArea.containsMouse ? 1.2 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    
                    // 呼吸动画属性
                    property real updateBreathingOpacity: 1.0
                    SequentialAnimation on updateBreathingOpacity {
                        running: updateManager.hasUpdate && !mainWindow.isChecking
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.5; duration: 1200; easing.type: Easing.InOutQuad } // 降低透明度下限增强呼吸感
                        NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                    }

                    // 旋转动画
                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: mainWindow.isChecking
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    anchors.margins: -10 // 负边距大幅扩大点击热区
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                         if (updateManager.hasUpdate) {
                             updateDialog.open()
                             return
                         }

                         if (!mainWindow.isChecking) {
                             mainWindow.isChecking = true
                             toast.show("正在检查更新...", "#8899AA") // 灰色提示
                             updateManager.checkForUpdates(false)
                         }
                    }
                }
            }
        }

        // Update Dialog Overlay
        // ========================================================================
        Rectangle {
            id: updateDialog
            visible: false
            anchors.centerIn: parent
            width: 200 // 更小巧的宽度
            height: 140 // 更紧凑的高度
            radius: 16 // 更柔和的圆角
            color: "#F01B2A4E" // 增加不透明度，提升质感
            border.color: dialogMouseArea.containsMouse ? 
                          Qt.lighter(mainWindow.themeColor, 1.3) : 
                          Qt.rgba(mainWindow.themeColor.r, mainWindow.themeColor.g, mainWindow.themeColor.b, 0.3)
            border.width: 1
            
            // 悬浮放大特效
            scale: dialogMouseArea.containsMouse ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            // 玻璃拟态光效 (顶部高光)
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.2)
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // 属性：下载状态
            property bool isDownloading: false
            
            function open() {
                visible = true
                isDownloading = false
                updateManager.resetStatus()
            }
            
            function close() {
                visible = false
            }

            // 阻止鼠标点击穿透 + 悬浮检测
            MouseArea {
                id: dialogMouseArea
                anchors.fill: parent
                hoverEnabled: true 
                onClicked: {} // 拦截点击
            }

            // 内容布局
            Column {
                anchors.centerIn: parent
                width: parent.width - 30
                spacing: 8

                // 标题与版本号组合
                Item {
                    width: parent.width
                    height: 30
                    visible: !updateDialog.isDownloading
                    
                    Text {
                        text: "发现新版本"
                        color: "#8899AA"
                        font.pixelSize: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                    }
                    
                    Text {
                        text: "v" + updateManager.remoteVersion
                        color: mainWindow.themeColor
                        font.pixelSize: 18 // 放大版本号作为视觉重心
                        font.bold: true
                        font.family: "Segoe UI"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                    }
                }
                
                // 状态/进度区域
                Item {
                    width: parent.width
                    height: 40
                    
                    // 1. 简短询问 (非下载状态)
                    Text {
                        visible: !updateDialog.isDownloading
                        text: "立即更新体验新功能?"
                        color: "#DDDDDD"
                        font.pixelSize: 11
                        anchors.centerIn: parent
                        opacity: 0.8
                    }
                    
                    // 2. 进度条 (下载时显示)
                    Rectangle {
                        id: progressBar
                        visible: updateDialog.isDownloading
                        width: parent.width
                        height: 4
                        radius: 2
                        color: "#33000000"
                        anchors.centerIn: parent
                        
                        Rectangle {
                            height: parent.height
                            width: parent.width * updateManager.downloadProgress
                            color: mainWindow.themeColor
                            radius: 2
                        }
                    }
                    
                    // 3. 下载状态文本
                    Text {
                        visible: updateDialog.isDownloading
                        text: updateManager.updateStatus
                        color: "#AAAAAA"
                        font.pixelSize: 9
                        width: parent.width
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        anchors.top: progressBar.bottom
                        anchors.topMargin: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // 按钮组
                Row {
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !updateDialog.isDownloading

                    // 暂不按钮 (纯文字，极简)
                    Rectangle {
                        width: 70
                        height: 28
                        color: "transparent"
                        radius: 14
                        
                        Text {
                            text: "稍后"
                            color: hoverHandler1.hovered ? "#FFFFFF" : "#8899AA"
                            anchors.centerIn: parent
                            font.pixelSize: 11
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        
                        HoverHandler { id: hoverHandler1 }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: updateDialog.close()
                        }
                    }

                    // 立即更新按钮 (高亮胶囊)
                    Rectangle {
                        width: 80
                        height: 28
                        color: mainWindow.themeColor
                        radius: 14
                        // 简单的光泽感
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.lighter(mainWindow.themeColor, 1.2) }
                            GradientStop { position: 1.0; color: mainWindow.themeColor }
                        }
                        
                        Text {
                            text: "更新"
                            // 优化对比度：使用深色文字 (#0B1015) 搭配高亮背景
                            color: "#0B1015" 
                            anchors.centerIn: parent
                            font.bold: true
                            font.pixelSize: 11
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                updateDialog.isDownloading = true
                                updateManager.startDownload("")
                            }
                        }
                    }
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
            // 只有当全局提醒激活且不在午休模式时显示
            visible: isReminderActive && !timerEngine.isNapMode
            
            onReminderFinished: {
                isReminderActive = false
                // 自动开启下一轮工作倒计时
                timerEngine.startWork()
            }
            onSnoozeRequested: {
                timerEngine.snooze()
                isReminderActive = false
            }
        }
    }
    
    // 多屏实例化午休窗口
    Instantiator {
        model: Qt.application.screens
        delegate: NapWindow {
            screen: modelData // 绑定到对应屏幕
            // 由 TimerEngine 内部状态控制显示，NapWindow 内部已绑定 visible: timerEngine.isNapMode
            // 但为了确保每个实例都能正确响应，这里不需要额外绑定 visible，
            // 因为 NapWindow 内部的 visible: timerEngine.isNapMode 是对单例 TimerEngine 的绑定。
        }
    }

    Connections {
        target: timerEngine
        function onReminderTriggered() {
            // 如果正在午休，不打扰
            if (timerEngine.isNapMode) return;
            
            themeController.generateRandomTheme()
            isReminderActive = true
        }
    }
}