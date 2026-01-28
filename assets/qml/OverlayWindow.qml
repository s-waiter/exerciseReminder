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

    // 公开方法：显示提醒
    function showReminder() {
        overlayWin.visible = true
        overlayWin.showFullScreen()
        overlayWin.raise()
        // 重启动画
        mainEntranceAnim.restart()
    }

    // 1. 动态渐变背景 (清新活力色调)
    Rectangle {
        id: bg
        anchors.fill: parent
        gradient: Gradient {
            // 深青色 -> 清新绿
            GradientStop { position: 0.0; color: "#134E5E" }
            GradientStop { position: 1.0; color: "#71B280" }
        }
        
        // 背景呼吸动画
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 0.9; to: 1.0; duration: 3000 }
            NumberAnimation { from: 1.0; to: 0.9; duration: 3000 }
        }
    }

    // 2. 粒子系统 (上升的气泡/能量点)
    ParticleSystem {
        id: particles
        anchors.fill: parent
        // 仅在窗口显示时运行以节省资源
        running: overlayWin.visible
        
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
            // 向上运动，带随机摆动
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
        
        // 入场动画组合
        ParallelAnimation {
            id: mainEntranceAnim
            NumberAnimation { target: contentCard; property: "scale"; to: 1.0; duration: 800; easing.type: Easing.OutBack }
            NumberAnimation { target: contentCard; property: "opacity"; to: 1.0; duration: 500 }
        }

        // 脉动光环 (Visual Urgency)
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
                NumberAnimation { from: 1.0; to: 1.3; duration: 1200 } // 快节奏脉动
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
            
            // 内部图标
            Text {
                anchors.centerIn: parent
                text: "🏃" 
                font.pixelSize: 100
            }
            
            // 动态进度圈
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
                text: "身体是革命的本钱，起来充充电吧 ⚡"
                color: "#E0F2F1"
                font.pixelSize: 22
                font.letterSpacing: 1
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    
    // 4. 底部按钮区 (悬浮)
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 50
        
        // 自定义大按钮组件
        component ActionButton: Button {
            property string mainColor: "#ffffff"
            property string textColor: "#134E5E"
            
            width: 220
            height: 70
            
            background: Rectangle {
                color: parent.down ? Qt.darker(mainColor, 1.1) : mainColor
                radius: 35
                
                // 简单的内发光/立体感
                Rectangle {
                    anchors.fill: parent
                    radius: 35
                    color: "white"
                    opacity: parent.parent.hovered ? 0.2 : 0
                }
                
                // 按钮阴影
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 5
                    z: -1
                    radius: 35
                    color: "black"
                    opacity: 0.2
                }
            }
            
            contentItem: Text {
                text: parent.text
                color: textColor
                font.pixelSize: 22
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            // 按钮弹出动画
            scale: 0
            onVisibleChanged: if(visible) showAnim.restart()
            NumberAnimation on scale {
                id: showAnim
                from: 0; to: 1.0
                duration: 600
                easing.type: Easing.OutBack
                running: false
            }
        }

        ActionButton {
            text: "✅ 完成运动"
            mainColor: "#ffffff"
            textColor: "#134E5E"
            onClicked: {
                timerEngine.startWork()
                overlayWin.visible = false
            }
        }
        
        ActionButton {
            text: "💤 稍后提醒"
            mainColor: "#33000000" // 半透明黑
            textColor: "#ffffff"
            
            background: Rectangle {
                color: parent.down ? "#55000000" : "#33000000"
                radius: 35
                border.color: "white"
                border.width: 2
            }
            
            onClicked: {
                timerEngine.snooze()
                overlayWin.visible = false
            }
        }
    }
}
