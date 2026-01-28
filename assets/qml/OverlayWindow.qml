import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Particles 2.0

Window {
    id: overlayWin
    visible: false
    // 强制全屏 + 置顶 + 无边框
    flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
    visibility: Window.FullScreen
    color: "transparent"

    // -------------------------------------------------------------------------
    // 过程化主题引擎 (Procedural Theme Engine)
    // -------------------------------------------------------------------------

    // 当前激活的主题状态
    property var currentTheme: {
        "gradientStart": "#134E5E",
        "gradientEnd": "#71B280",
        "accentColor": "#ffffff",
        "textColor": "#134E5E",
        "icon": "🏃",
        "particleShape": "circle",
        "centerVisual": "circle_ring" 
    }

    // 预设调色板库 (清新、科技、赛博、自然、深邃)
    property var colorPalettes: [
        { s: "#134E5E", e: "#71B280", t: "#134E5E" }, // Fresh Mint
        { s: "#2b5876", e: "#4e4376", t: "#2b5876" }, // Deep Space
        { s: "#ff512f", e: "#dd2476", t: "#dd2476" }, // Sunset Energy
        { s: "#000000", e: "#434343", t: "#434343" }, // Minimal Dark
        { s: "#1A2980", e: "#26D0CE", t: "#1A2980" }, // Aqua Marine
        { s: "#CC95C0", e: "#19547b", t: "#19547b" }, // Cyber Grape
        { s: "#EB3349", e: "#F45C43", t: "#EB3349" }, // Energetic Red
        { s: "#4CA1AF", e: "#C4E0E5", t: "#4CA1AF" }, // Calm Breeze
        { s: "#8360c3", e: "#2ebf91", t: "#8360c3" }, // Mystic Green
        { s: "#00bf8f", e: "#001510", t: "#00bf8f" }  // Matrix Neo
    ]

    // 图标库
    property var icons: ["🏃", "🧘", "🤸", "🏋️", "🚶", "🕺", "💃", "🧗", "🚴", "🏊"]

    // 粒子形状库
    property var particleShapes: ["circle", "square", "line"]

    // 中心视觉库
    property var centerVisuals: ["circle_ring", "tech_hexagon", "radar_scan", "energy_pulse"]

    // 随机语录库
    property var quotes: [
        "身体是革命的本钱，起来充充电吧 ⚡",
        "久坐伤身，动动更健康 🏃",
        "喝口水，伸个懒腰，精神百倍 💪",
        "现在的休息，是为了更好的出发 🚀",
        "保护脊椎，人人有责 🦴",
        "在这个Bug改完之前，先改改你的坐姿 🧘",
        "代码可以重构，身体只有一个 ❤️",
        "离开椅子，你的灵感才会回来 💡",
        "颈椎在哭泣，快去救救它 🚑",
        "动起来，让多巴胺飞一会儿 🧠"
    ]

    // 随机生成主题
    function generateRandomTheme() {
        // 1. 随机调色板
        var pal = colorPalettes[Math.floor(Math.random() * colorPalettes.length)];
        
        // 2. 随机图标
        var icn = icons[Math.floor(Math.random() * icons.length)];
        
        // 3. 随机粒子
        var pShape = particleShapes[Math.floor(Math.random() * particleShapes.length)];
        
        // 4. 随机中心视觉
        var cVis = centerVisuals[Math.floor(Math.random() * centerVisuals.length)];

        currentTheme = {
            "gradientStart": pal.s,
            "gradientEnd": pal.e,
            "accentColor": "#ffffff",
            "textColor": pal.t, // 按钮文字颜色取深色
            "icon": icn,
            "particleShape": pShape,
            "centerVisual": cVis
        };
        
        // 5. 随机语录
        var qIdx = Math.floor(Math.random() * quotes.length);
        quoteText.text = quotes[qIdx];
    }

    // 公开方法：显示提醒
    function showReminder() {
        generateRandomTheme(); // 每次显示前重新生成

        overlayWin.visible = true
        overlayWin.showFullScreen()
        overlayWin.raise()
        
        // 重启动画
        mainEntranceAnim.restart()
        bgAnim.restart()
    }

    // -------------------------------------------------------------------------
    // UI 实现
    // -------------------------------------------------------------------------

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

    // 2. 粒子系统
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

    // 3. 核心内容区
    Item {
        id: contentCard
        width: 600
        height: 600
        anchors.centerIn: parent
        scale: 0.8
        opacity: 0
        z: 1 
        
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
                            ctx.setLineDash([15, 30])
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
                text: "TIME TO MOVE!"
                color: "white"
                font.pixelSize: 48
                font.bold: true
                font.letterSpacing: 4
                font.family: "Segoe UI Black"
                anchors.horizontalCenter: parent.horizontalCenter
                style: Text.Outline
                styleColor: currentTheme.textColor
            }
            
            Text {
                id: quoteText
                text: "身体是革命的本钱，起来充充电吧 ⚡"
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
                timerEngine.startWork()
                overlayWin.visible = false
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
                timerEngine.snooze()
                overlayWin.visible = false
            }
        }
    }
}
