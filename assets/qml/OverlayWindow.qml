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

    // 随机语录库
    property var quotes: [
        "身体是革命的本钱，起来充充电吧 ⚡",
        "久坐伤身，动动更健康 🏃",
        "喝口水，伸个懒腰，精神百倍 💪",
        "现在的休息，是为了更好的出发 🚀",
        "保护脊椎，人人有责 🦴",
        "在这个Bug改完之前，先改改你的坐姿 🧘",
        "代码可以重构，身体只有一个 ❤️"
    ]

    // 公开方法：显示提醒
    function showReminder() {
        // 随机切换语录
        var idx = Math.floor(Math.random() * quotes.length);
        quoteText.text = quotes[idx];

        overlayWin.visible = true
        overlayWin.showFullScreen()
        overlayWin.raise()
        // 重启动画
        mainEntranceAnim.restart()
    }

    // 1. 动态渐变背景
    Rectangle {
        id: bg
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#134E5E" }
            GradientStop { position: 1.0; color: "#71B280" }
        }
        
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 0.9; to: 1.0; duration: 3000 }
            NumberAnimation { from: 1.0; to: 0.9; duration: 3000 }
        }
    }

    // 2. 粒子系统
    ParticleSystem {
        id: particles
        anchors.fill: parent
        running: overlayWin.visible
        z: 0 // 确保在底层
        
        ItemParticle {
            delegate: Rectangle {
                width: 15 * Math.random() + 5
                height: width
                radius: width/2
                color: "white"
                opacity: 0.2
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
            velocity: PointDirection { y: -150; yVariation: 80; xVariation: 30 }
            acceleration: PointDirection { y: -30 }
        }
    }

    // 3. 核心内容区
    Item {
        id: contentCard
        width: 600
        height: 500
        anchors.centerIn: parent
        scale: 0.8
        opacity: 0
        z: 1 // 内容层级提升
        
        ParallelAnimation {
            id: mainEntranceAnim
            NumberAnimation { target: contentCard; property: "scale"; to: 1.0; duration: 800; easing.type: Easing.OutBack }
            NumberAnimation { target: contentCard; property: "opacity"; to: 1.0; duration: 500 }
        }

        // 脉动光环
        Rectangle {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -60
            width: 300
            height: 300
            radius: 150
            color: "transparent"
            border.color: "#ffffff"
            border.width: 2
            opacity: 0.3
            
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.3; duration: 1200 }
                NumberAnimation { from: 1.3; to: 1.0; duration: 1200 }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.6; to: 0.0; duration: 1200 }
                NumberAnimation { from: 0.0; to: 0.6; duration: 1200 }
            }
        }

        // 中心图标区
        Rectangle {
            id: iconBg
            width: 220
            height: 220
            radius: 110
            color: "#ffffff"
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -60
            
            Text {
                anchors.centerIn: parent
                text: "🏃" 
                font.pixelSize: 100
            }
            
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.strokeStyle = "#71B280"
                    ctx.lineWidth = 10
                    ctx.beginPath()
                    ctx.arc(width/2, height/2, width/2-5, 0, 2*Math.PI)
                    ctx.stroke()
                }
            }

            // 科技感旋转虚线圈
            Item {
                anchors.fill: parent
                anchors.margins: -25
                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0; to: 360; duration: 20000
                }
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.5)"
                        ctx.lineWidth = 2
                        ctx.setLineDash([15, 30]) // 虚线样式
                        ctx.beginPath()
                        ctx.arc(width/2, height/2, width/2-2, 0, 2*Math.PI)
                        ctx.stroke()
                    }
                }
            }
        }
        
        // 文字区
        Column {
            anchors.top: iconBg.bottom
            anchors.topMargin: 50
            anchors.horizontalCenter: parent.horizontalCenter
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
                styleColor: "#134E5E"
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
    // 修正：显式提升 Z 轴层级，移除不稳定的入场动画，确保绝对可见
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 50
        z: 100 // 确保在最上层，绝对可点击

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
                color: "#134E5E"
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
