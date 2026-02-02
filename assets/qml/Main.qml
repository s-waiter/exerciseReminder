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
    
    // 初始化标志，防止启动时的属性变化触发不必要的动画或位移逻辑
    property bool isInitialized: false

    // 启动时静默检查更新
    Component.onCompleted: {
        updateManager.checkForUpdates(true)
        
        // 检查是否是开机自启
        if (isAutoStartLaunch) {
            // 开机自启：使用 Timer 延迟执行位置设置，确保屏幕信息已就绪且避免初始化冲突
            // 延迟时间增加到 300ms，确保系统完全就绪
            autoStartTimer.start()
        } else {
            // 手动启动：直接展示主界面，并居中显示
            // 关键修正：先临时禁用动画，确保初始位置设置是瞬时的，而不是从(0,0)飞过来
            animationEnabled = false
            centerWindow()
            isInitialized = true
            // 稍后恢复动画，以便后续的拖拽或模式切换有动画效果
            enableAnimTimer.start()
        }
    }

    // 辅助函数：居中窗口
    function centerWindow() {
        // 智能定位：获取鼠标当前所在屏幕的几何信息
        // 这样用户在哪个屏幕双击启动，窗口就出现在哪个屏幕中央
        var geo = windowUtils.getScreenGeometryAtCursor()
        if (geo) {
            var availW = geo.width
            var availH = geo.height
            var startX = geo.x
            var startY = geo.y
            
            // 此时 isPinned 为 false (默认)，使用正常尺寸
            mainWindow.x = startX + (availW - mainWindow.width) / 2
            mainWindow.y = startY + (availH - mainWindow.height) / 2
        }
    }

    Timer {
        id: autoStartTimer
        interval: 300 // 增加延迟以确保窗口系统准备就绪 (100ms -> 300ms)
        repeat: false
        onTriggered: {
            // 如果是开机自启，则直接进入 Mini 模式 (悬浮球)
            // 先禁用动画，避免飞入效果
            animationEnabled = false
            
            isPinned = true
            
            // 计算屏幕右上角位置
            // 使用 C++ 提供的准确主屏幕几何信息
            var geo = windowUtils.getPrimaryScreenAvailableGeometry()
            if (geo) {
                var availW = geo.width
                var startX = geo.x
                var startY = geo.y
                
                // 悬浮球尺寸 120x120
                var targetX = startX + availW - 120 - 50 // 右侧留出 50px 边距
                var targetY = startY + 100 // 顶部留出 100px 边距
                
                mainWindow.x = targetX
                mainWindow.y = targetY
            }
            
            // 恢复动画 (延迟一点点确保位置生效后)
            enableAnimTimer.start()
            
            // 标记初始化完成，此时窗口才会变为 visible
            isInitialized = true
        }
    }
    
    Timer {
        id: enableAnimTimer
        interval: 100
        repeat: false
        onTriggered: animationEnabled = true
    }
    
    // 动态调整窗口大小：
    // isPinned (迷你模式): 120x120
    // Normal (正常模式): 280x420 (恢复到用户觉得舒适的尺寸)
    width: isPinned ? 120 : 280
    height: isPinned ? 120 : 420
    
    // 完美启动逻辑：
    // 1. 默认 visible 为 false (由 isInitialized 控制)，确保窗口在定位完成前不可见
    // 2. Component.onCompleted 中根据启动模式计算位置
    // 3. 定位完成后设置 isInitialized = true，窗口平滑显示
    // 这彻底避免了窗口先在屏幕中间闪烁一下再跳到右上角，或在错误位置显示的“视觉抖动”，实现“无感启动”。
    visible: isInitialized
    
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
    // 动画控制开关
    property bool animationEnabled: true
    
    // 当 width, height, x, y 发生变化时，不立即突变，而是应用缓动动画。
    // 极致丝滑配置：
    // duration: 600ms (延长时长以展示 OutExpo 尾部极其细腻的减速过程)
    // easing.type: Easing.OutExpo (指数级缓出，启动极快，刹车如羽毛般轻盈，是高端 UI 的标配)
    Behavior on width { 
        enabled: animationEnabled
        NumberAnimation { duration: 600; easing.type: Easing.OutExpo } 
    }
    Behavior on height { 
        enabled: animationEnabled
        NumberAnimation { duration: 600; easing.type: Easing.OutExpo } 
    }
    Behavior on x { 
        enabled: animationEnabled
        NumberAnimation { duration: 600; easing.type: Easing.OutExpo } 
    }
    Behavior on y { 
        enabled: animationEnabled
        NumberAnimation { duration: 600; easing.type: Easing.OutExpo } 
    }

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
        
        // 注意：如果是程序启动时的初始化阶段 (isInitialized == false)，
        // 我们不执行这个位移补偿。因为此时我们正在通过代码强制设置窗口的初始位置 (例如右上角)，
        // 任何额外的位移都会破坏这个定位。
        if (!isInitialized) return
        
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
            // 只有在手动检查模式下才弹窗，自动检查模式下静默处理（只闪烁图标）
            if (mainWindow.isChecking) {
                updateDialog.open()
            }
            mainWindow.isChecking = false 
        }
        function onNoUpdateAvailable() { 
            if (mainWindow.isChecking) {
                toast.show("当前已是最新版本", "#00d2ff") // 使用主题蓝
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
                Behavior on radius { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
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
                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                
                // 位置平滑过渡
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                
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
            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
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
                    text: "久坐运动提醒"
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
                
                // 设置按钮
                Button {
                    id: settingsBtn
                    width: 30 // 恢复为 30 以便与关闭按钮高度对齐 (视觉中心对齐)
                    height: 30
                    visible: !mainWindow.isPinned // 迷你模式下隐藏
                    background: Rectangle { color: "transparent" }
                    contentItem: Text {
                        text: "⚙" // Gear icon
                        color: "white"
                        font.pixelSize: 15 // 保持精致的字号
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: settingsBtn.hovered ? 1.0 : 0.6
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    onClicked: settingsOverlay.open()
                }

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
            
            // 关键：TopMargin 必须严格同步 Window 几何动画 (OutExpo)，消除抖动
            // Width/Height 使用带轻微回弹的曲线 (OutBack)，增加活力与弹性
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
            
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
                
                // 使用 State 和 Transition 明确管理状态切换，避免视觉重叠
                state: (isPinned && centerMouseArea.containsMouse) ? "PEEK" : "COUNTDOWN"

                states: [
                    State {
                        name: "COUNTDOWN"
                        PropertyChanges { target: countdownState; opacity: 1.0; scale: 1.0 }
                        PropertyChanges { target: peekState; opacity: 0.0; scale: 1.1 }
                    },
                    State {
                        name: "PEEK"
                        PropertyChanges { target: countdownState; opacity: 0.0; scale: 0.8 }
                        PropertyChanges { target: peekState; opacity: 1.0; scale: 1.0 }
                    }
                ]

                transitions: [
                    Transition {
                        from: "COUNTDOWN"; to: "PEEK"
                        // 关键修复：串行执行动画。先隐藏倒计时，再显示 Peek，彻底杜绝重叠 ghosting
                        SequentialAnimation {
                            ParallelAnimation {
                                NumberAnimation { target: countdownState; property: "opacity"; duration: 150; easing.type: Easing.OutQuad }
                                NumberAnimation { target: countdownState; property: "scale"; duration: 150; easing.type: Easing.OutQuad }
                            }
                            ParallelAnimation {
                                NumberAnimation { target: peekState; property: "opacity"; duration: 300; easing.type: Easing.OutCubic }
                                NumberAnimation { target: peekState; property: "scale"; duration: 300; easing.type: Easing.OutBack }
                            }
                        }
                    },
                    Transition {
                        from: "PEEK"; to: "COUNTDOWN"
                        // 恢复时可以并行，稍微错开一点即可
                        ParallelAnimation {
                            NumberAnimation { target: peekState; property: "opacity"; duration: 200; easing.type: Easing.OutQuad }
                            NumberAnimation { target: countdownState; property: "opacity"; duration: 300; easing.type: Easing.OutCubic }
                            NumberAnimation { target: countdownState; property: "scale"; duration: 300; easing.type: Easing.OutBack }
                        }
                    }
                ]
                
                // 1. 默认状态：倒计时 (Countdown State)
                Item {
                    id: countdownState
                    anchors.fill: parent
                    
                    // 移除原来的属性绑定和 Behavior，交由父容器 State 管理
                    opacity: 1.0 
                    scale: 1.0

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
                            
                            Behavior on font.pixelSize { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                        }
                        
                        Text {
                            text: timerEngine.statusText
                            color: mainWindow.themeColor
                            font.pixelSize: isPinned ? 10 : 12 // 动态字体大小
                            font.bold: true
                            font.family: "Microsoft YaHei UI"
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: isPinned ? 0.0 : 0.8
                            visible: opacity > 0 // 优化性能，看不见时不渲染
                            
                            // 高度动画实现平滑布局挤压
                            height: isPinned ? 0 : implicitHeight
                            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                            
                            Behavior on font.pixelSize { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                        }

                        // 预计结束时间 (ETA) - 正常模式下显示
                        Text {
                            text: "预计 " + timerEngine.estimatedFinishTime + " 运动"
                            color: "#8899A6" // 弱化显示
                            font.pixelSize: 12
                            font.family: "Microsoft YaHei UI"
                            
                            // 逻辑：Mini模式隐藏 OR 非工作状态隐藏
                            opacity: isPinned ? 0.0 : (timerEngine.statusText === "工作中" ? 1.0 : 0.0)
                            visible: opacity > 0
                            
                            height: visible ? implicitHeight : 0
                            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                            
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // 2. 透视状态：预计休息时间 (Smart Peek State)
                Item {
                    id: peekState
                    anchors.fill: parent
                    
                    // 移除原来的属性绑定和 Behavior，交由父容器 State 管理
                    opacity: 0.0
                    scale: 1.1
                    visible: opacity > 0 // 优化性能
                    
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
                            text: "预计运动"
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

            // 交互层：点击暂停/继续，双击切换模式，三击立即休息，右击菜单
            MouseArea {
                id: centerMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true // 开启悬停以显示详细 ETA
                acceptedButtons: Qt.LeftButton | Qt.RightButton // 启用右键点击

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
                        // 触发立即运动
                        themeController.generateRandomTheme()
                        isReminderActive = true
                    }
                }
                
                onPressed: {
                    // 右键点击直接打开菜单，不参与多击逻辑
                    if (mouse.button === Qt.RightButton) {
                        return
                    }

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
                    // 右键拖拽也支持移动窗口
                    
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
                    // 右键处理
                    if (mouse.button === Qt.RightButton) {
                        // 仅在迷你模式 (isPinned) 下显示右键菜单
                        if (mainWindow.isPinned) {
                            var globalPos = centerMouseArea.mapToGlobal(mouseX, mouseY)
                            quickMenu.x = globalPos.x + 10
                            quickMenu.y = globalPos.y + 10
                            quickMenu.show()
                            quickMenu.requestActivate() // 强制获取焦点，确保 onActiveChanged 能正常触发关闭
                        }
                        return
                    }

                    // 左键处理
                    // 只有在非拖拽且非三击序列中才触发暂停
                    // 如果 clickCount >= 3，说明是三击操作的一部分，不应触发单击逻辑
                    if (!isDrag && clickCount < 3) {
                        clickTimer.start()
                    }
                }
                
                onDoubleClicked: {
                    // 仅响应左键双击
                    if (mouse.button !== Qt.LeftButton) return

                    // 双击切换模式
                    // 增加条件：只有当点击计数小于3时才处理双击
                    // 避免四击操作中(第3、4次点击)触发第二次双击事件，导致误切换模式
                    if (!isDrag && clickCount < 3) {
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

            // === 右键快捷菜单 (Glassmorphism Style - 独立窗口以突破父窗口边界) ===
            Window {
                id: quickMenu
                width: 140
                height: menuColumn.height + 16 // 增加内边距
                flags: Qt.Popup | Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint
                color: "transparent"
                
                // 失去焦点时自动关闭 (模拟 Popup 行为)
                onActiveChanged: {
                    if (!active) close()
                }

                // 菜单容器 (用于整体缩放动画)
                Item {
                    id: menuContainer
                    anchors.fill: parent
                    anchors.margins: 4 // 留出边缘给阴影或缩放空间
                    scale: 1.0
                    
                    // 鼠标移入时的交互反馈
                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: menuAnim.start()
                        onExited: menuAnimReverse.start()
                    }

                    // 缩放动画
                    ParallelAnimation {
                        id: menuAnim
                        NumberAnimation { target: menuContainer; property: "scale"; to: 1.05; duration: 200; easing.type: Easing.OutBack }
                    }
                    ParallelAnimation {
                        id: menuAnimReverse
                        NumberAnimation { target: menuContainer; property: "scale"; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                    }

                    Rectangle {
                        id: menuBgRect
                        anchors.fill: parent
                        radius: 12
                        // 动态边框颜色：默认微亮，悬停高亮
                        border.color: hoverArea.containsMouse ? "#8000d2ff" : "#3300d2ff"
                        border.width: 1
                        
                        // 背景渐变：从深蓝到更深蓝，但增加一点青色倾向，呼应悬浮球
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#F21A2838" } // 稍亮的蓝灰色
                            GradientStop { position: 1.0; color: "#F20B121E" } // 深邃底色
                        }
                        
                        // 模拟内部微光 (Top highlight)
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#40ffffff"
                            anchors.top: parent.top
                            anchors.topMargin: 1
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            opacity: 0.5
                        }
                    }
                    
                    Column {
                        id: menuColumn
                        width: parent.width
                        anchors.centerIn: parent
                        spacing: 4
                        
                        // 菜单项组件
                        component MenuItemRow : Rectangle {
                            id: menuItem
                            width: parent.width - 16 // 左右留白
                            height: 34
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: hoverArea.containsMouse ? "#2000d2ff" : "transparent" // 悬停使用青色微光
                            radius: 8
                            
                            property string icon: ""
                            property string label: ""
                            property string shortcut: ""
                            signal triggered()
                            
                            // 图标
                            Text {
                                id: iconText
                                text: menuItem.icon
                                color: hoverArea.containsMouse ? "#00d2ff" : "#AAB8C2" // 悬停变青色
                                font.pixelSize: 15
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                horizontalAlignment: Text.AlignHCenter
                                scale: hoverArea.containsMouse ? 1.1 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150 } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            
                            // 标签
                            Text {
                                id: labelText
                                text: menuItem.label
                                color: hoverArea.containsMouse ? "#ffffff" : "#E1E8ED" // 默认更亮一点的灰
                                font.pixelSize: 12
                                font.family: "Microsoft YaHei UI"
                                font.bold: hoverArea.containsMouse
                                anchors.left: iconText.right
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            // 快捷键
                            Text {
                                text: menuItem.shortcut
                                color: hoverArea.containsMouse ? "#00d2ff" : "#556677" // 悬停变青色
                                font.pixelSize: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: 0.8
                            }
                            
                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    menuItem.triggered()
                                    quickMenu.close()
                                }
                            }
                        }
                        
                        // 顶部间距
                        Item { width: 1; height: 2 }

                        MenuItemRow {
                            icon: timerEngine.isRunning ? "⏸" : "▶"
                            label: timerEngine.isRunning ? "暂停计时" : "继续计时"
                            shortcut: "单击"
                            onTriggered: timerEngine.togglePause()
                        }
                        
                        MenuItemRow {
                            icon: "⇋" 
                            label: "切换模式"
                            shortcut: "双击"
                            onTriggered: mainWindow.isPinned = !mainWindow.isPinned
                        }
                        
                        MenuItemRow {
                            icon: "⚡"
                            label: "立即运动"
                            shortcut: "三击"
                            onTriggered: {
                                themeController.generateRandomTheme()
                                isReminderActive = true
                            }
                        }
                        
                        MenuItemRow {
                            icon: "☾"
                            label: "午休助眠"
                            shortcut: "四击"
                            onTriggered: timerEngine.startNap()
                        }
                        
                        // 底部间距
                        Item { width: 1; height: 2 }
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
                    width: 95 // 增加宽度
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
                    width: 95 // 增加宽度
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
                    text: "立即运动"
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
        
        // Update Logic Connections - 已移除冗余的 Connections，统一由顶层 Connections 处理
        // ========================================================================

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

    // ========================================================================
    // 设置弹窗 (Settings Overlay)
    // ========================================================================
    // 采用与 UpdateDialog 完全一致的视觉风格
    Item {
        id: settingsOverlay
        anchors.fill: parent
        visible: false
        z: 200 // 确保在最上层
        
        function open() { visible = true }
        function close() { visible = false }

        // 点击背景关闭
        MouseArea {
            anchors.fill: parent
            onClicked: settingsOverlay.close()
        }
        
        Rectangle {
            id: settingsDialog
            anchors.centerIn: parent
            width: 200 
            height: 140 
            radius: 16 
            color: "#F01B2A4E" // 增加不透明度，提升质感
            border.color: settingsDialogMouseArea.containsMouse ? 
                          Qt.lighter(mainWindow.themeColor, 1.3) : 
                          Qt.rgba(mainWindow.themeColor.r, mainWindow.themeColor.g, mainWindow.themeColor.b, 0.3)
            border.width: 1
            
            // 悬浮放大特效
            scale: settingsDialogMouseArea.containsMouse ? 1.05 : 1.0
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
            
            // 阻止点击穿透 + 悬浮检测
            MouseArea {
                id: settingsDialogMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {} // 拦截点击
            }
            
            // 内容
            Column {
                anchors.centerIn: parent
                width: parent.width - 30
                spacing: 12
                
                Text {
                    text: "偏好设置"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // 分割线
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#22ffffff"
                }
                
                // 开机自启开关
                Item {
                    width: parent.width
                    height: 20
                    
                    Text {
                        text: "开机自启"
                        color: "#DDDDDD"
                        font.pixelSize: 12
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -2 // 向上微调 2px 以视觉对齐右侧开关
                    }
                    
                    Switch {
                        checked: appConfig.autoStart
                        onToggled: appConfig.autoStart = checked
                        
                        scale: 0.7 // 稍微缩小开关以适应紧凑布局
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        
                        indicator: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 20
                            radius: 10
                            color: parent.checked ? mainWindow.themeColor : "#33ffffff"
                            border.color: parent.checked ? mainWindow.themeColor : "#cccccc"
                            
                            Rectangle {
                                x: parent.parent.checked ? parent.width - width - 2 : 2
                                width: 16
                                height: 16
                                radius: 8
                                color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on x { NumberAnimation { duration: 100 } }
                            }
                        }
                    }
                }

                // 强制运动开关
                Item {
                    width: parent.width
                    height: 20
                    
                    Text {
                        text: "强制运动"
                        color: "#DDDDDD"
                        font.pixelSize: 12
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -2
                    }
                    
                    Switch {
                        id: forcedExerciseSwitch
                        checked: appConfig.forcedExercise
                        onToggled: appConfig.forcedExercise = checked
                        
                        scale: 0.7
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        
                        indicator: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 20
                            radius: 10
                            color: parent.checked ? mainWindow.themeColor : "#33ffffff"
                            border.color: parent.checked ? mainWindow.themeColor : "#cccccc"
                            
                            Rectangle {
                                x: parent.parent.checked ? parent.width - width - 2 : 2
                                width: 16
                                height: 16
                                radius: 8
                                color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on x { NumberAnimation { duration: 100 } }
                            }
                        }
                    }
                }

                // 强制运动时长设置 (仅当强制运动开启时显示)
                Item {
                    width: parent.width
                    height: 20
                    visible: appConfig.forcedExercise
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    
                    Text {
                        text: "强制时长"
                        color: "#999999"
                        font.pixelSize: 12
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        
                        // 减号按钮
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: "#33ffffff"
                            border.color: "#66ffffff"
                            border.width: 1
                            
                            Text {
                                text: "-"
                                color: "white"
                                anchors.centerIn: parent
                                font.pixelSize: 14
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (appConfig.forcedExerciseDuration > 1) {
                                        appConfig.forcedExerciseDuration -= 1
                                    }
                                }
                            }
                        }
                        
                        // 数值显示
                        Text {
                            text: appConfig.forcedExerciseDuration + " min"
                            color: "white"
                            font.pixelSize: 12
                            width: 35
                            horizontalAlignment: Text.AlignHCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        // 加号按钮
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: "#33ffffff"
                            border.color: "#66ffffff"
                            border.width: 1
                            
                            Text {
                                text: "+"
                                color: "white"
                                anchors.centerIn: parent
                                font.pixelSize: 14
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (appConfig.forcedExerciseDuration < 5) {
                                        appConfig.forcedExerciseDuration += 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 进入动画
            onVisibleChanged: {
                if (visible) {
                    enterAnim.restart()
                }
            }
            
            ParallelAnimation {
                id: enterAnim
                NumberAnimation { target: settingsDialog; property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
                NumberAnimation { target: settingsDialog; property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutBack }
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