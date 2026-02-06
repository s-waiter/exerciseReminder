import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import QtQuick.Particles 2.0

Window {
    id: reminderWin
    width: Screen.width
    height: Screen.height
    // Ensure it covers everything
    flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
    color: "transparent"
    visible: false
    
    property string titleStr: "提醒"
    property string messageStr: "时间到了！"
    property int type: 0 // 0:Work, 1:Life, 2:Anniversary, 3:Health
    property string scheduleId: ""
    property bool forceMode: false
    property int forceDuration: 30 // Seconds
    
    // Background color based on type
    readonly property color bgColor: {
        switch(type) {
            case 0: return "#1A1A2E"; // Work: Dark Blue
            case 1: return "#FFF3E0"; // Life: Warm Orange/Beige
            case 2: return "#2E0010"; // Anniversary: Dark Pink/Red
            case 3: return "#E0F7FA"; // Health: Light Cyan
            default: return "#000000";
        }
    }
    
    // Text color
    readonly property color textColor: {
        switch(type) {
            case 0: return "#FFFFFF";
            case 1: return "#5D4037";
            case 2: return "#FFD1DC";
            case 3: return "#006064";
            default: return "#FFFFFF";
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: bgColor
        opacity: 0.0
        
        Behavior on opacity { NumberAnimation { duration: 500 } }
        
        Component.onCompleted: opacity = 0.95
    }

    // 1. Anniversary Particles (Heart shapes)
    ParticleSystem {
        id: heartSys
        anchors.fill: parent
        running: type === 2 && reminderWin.visible
        
        ItemParticle {
            delegate: Text {
                text: "❤"
                font.pixelSize: 40
                color: "#FF4081"
            }
            fade: true
        }
        
        Emitter {
            anchors.fill: parent
            emitRate: 10
            lifeSpan: 4000
            size: 24
            sizeVariation: 8
            velocity: AngleDirection { angle: 90; angleVariation: 360; magnitude: 50 }
        }
    }
    
    // 2. Health: Water Animation (Simplified as rising blue rect)
    Rectangle {
        id: waterRect
        width: 300
        height: 0
        color: "#00B0FF"
        anchors.bottom: contentCol.top
        anchors.bottomMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        visible: type === 3 && titleStr.indexOf("喝水") >= 0 && reminderWin.visible
        opacity: 0.6
        radius: 20
        
        SequentialAnimation {
            running: waterRect.visible
            loops: Animation.Infinite
            NumberAnimation { target: waterRect; property: "height"; from: 20; to: 300; duration: 2000; easing.type: Easing.InOutQuad }
            NumberAnimation { target: waterRect; property: "height"; from: 300; to: 20; duration: 2000; easing.type: Easing.InOutQuad }
        }
        
        Text {
            anchors.centerIn: parent
            text: "💧"
            font.pixelSize: 60
        }
    }

    Column {
        id: contentCol
        anchors.centerIn: parent
        spacing: 30
        
        Text {
            text: titleStr
            font.pixelSize: 56
            font.bold: true
            color: textColor
            anchors.horizontalCenter: parent.horizontalCenter
            style: Text.Outline
            styleColor: Qt.rgba(0,0,0,0.2)
        }
        
        Text {
            text: messageStr
            font.pixelSize: 28
            color: textColor
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            width: 800
            wrapMode: Text.WordWrap
        }
        
        // Health: Eye Exercise Placeholder
        Rectangle {
            width: 640
            height: 360
            color: "black"
            visible: type === 3 && titleStr.indexOf("眼保健操") >= 0
            border.color: "white"
            border.width: 2
            
            Text {
                anchors.centerIn: parent
                text: "（模拟：此处播放眼保健操动画）\n请跟随节奏转动眼球 🙄"
                color: "white"
                font.pixelSize: 24
                horizontalAlignment: Text.AlignHCenter
            }
            
            // Simple animation for eyes
            Row {
                anchors.centerIn: parent
                spacing: 40
                visible: true
                Repeater {
                    model: 2
                    Rectangle {
                        width: 60; height: 60; radius: 30
                        color: "white"
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: "black"
                            x: 20; y: 20
                            SequentialAnimation {
                                running: true
                                loops: Animation.Infinite
                                NumberAnimation { property: "x"; to: 40; duration: 1000 } // Right
                                NumberAnimation { property: "y"; to: 40; duration: 1000 } // Down
                                NumberAnimation { property: "x"; to: 0; duration: 1000 } // Left
                                NumberAnimation { property: "y"; to: 0; duration: 1000 } // Up
                                NumberAnimation { property: "x"; to: 20; duration: 1000 } // Center
                                PauseAnimation { duration: 1000 }
                            }
                        }
                    }
                }
            }
        }
        
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            
            // "Prepared" Button (Only for Anniversary)
            Button {
                visible: type === 2 // Anniversary
                text: "🎁 已准备礼物"
                font.pixelSize: 22
                font.bold: true
                
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    opacity: enabled ? 1.0 : 0.3
                    color: "#880E4F"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: 200
                    implicitHeight: 60
                    opacity: enabled ? 1 : 0.3
                    color: "#FFD1DC"
                    radius: 30
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        color: "#40000000"
                    }
                }
                
                onClicked: {
                    scheduleManager.setPrepared(scheduleId, true)
                    bgRect.opacity = 0
                    closeTimer.start()
                }
            }

            Button {
                text: (forceMode && forceDuration > 0) ? "请完成任务..." : "完成 / 关闭"
                font.pixelSize: 22
                font.bold: true
                enabled: !(forceMode && forceDuration > 0)
                
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    opacity: enabled ? 1.0 : 0.3
                    color: type === 1 ? "#3E2723" : "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    implicitWidth: 200
                    implicitHeight: 60
                    opacity: enabled ? 1 : 0.3
                    color: type === 0 ? "#16213E" : (type === 1 ? "#FFCC80" : (type === 2 ? "#880E4F" : "#00ACC1"))
                    radius: 30
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        color: "#40000000"
                    }
                }
                
                onClicked: {
                    bgRect.opacity = 0
                    closeTimer.start()
                }
            }
        }
    }
    
    // Force Mode Timer
    Timer {
        id: forceTimer
        interval: 1000
        repeat: true
        running: forceMode && reminderWin.visible
        onTriggered: {
            if (forceDuration > 0) {
                forceDuration--
            } else {
                running = false
            }
        }
    }

    // Force Mode Countdown Display
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 40
        width: 100
        height: 100
        radius: 50
        color: "red"
        visible: forceMode && forceDuration > 0
        
        Text {
            anchors.centerIn: parent
            text: forceDuration
            color: "white"
            font.pixelSize: 40
            font.bold: true
        }
    }

    // Video Placeholder for Health + Force Mode
    Rectangle {
        id: videoPlaceholder
        width: 600
        height: 400
        color: "black"
        anchors.centerIn: parent
        visible: type === 3 && forceMode && reminderWin.visible
        
        Text {
            anchors.centerIn: parent
            text: "▶ 播放眼保健操教学视频..."
            color: "white"
            font.pixelSize: 30
        }
        
        SequentialAnimation on color {
            loops: Animation.Infinite
            ColorAnimation { from: "#000000"; to: "#222222"; duration: 1000 }
            ColorAnimation { from: "#222222"; to: "#000000"; duration: 1000 }
        }
    }

    Timer {
        id: closeTimer
        interval: 500
        onTriggered: reminderWin.destroy() // Destroy dynamic instance
    }
}
