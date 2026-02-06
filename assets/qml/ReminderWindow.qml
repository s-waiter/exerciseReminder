import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import QtQuick.Layouts 1.15
import QtQuick.Particles 2.0

Window {
    id: root
    width: 420
    height: 140 // Compact height
    
    // Position: Top Right (Default) - calculated in Component.onCompleted
    x: Screen.width - width - 30
    y: 30
    
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"
    visible: false
    
    property string titleStr: "提醒"
    property string messageStr: "时间到了！"
    property int type: 0 // 0:Work, 1:Life, 2:Anniversary, 3:Health
    property string scheduleId: ""
    property bool forceMode: false
    property int forceDuration: 30
    property int snoozeMinutes: 5 // Default snooze time
    
    signal snoozeRequested(int minutes)
    signal dismissRequested()
    
    function closeWindow() {
        closeAnim.start()
    }
    
    // Theme Colors (Cyberpunk/Neon Palette)
    readonly property color themeColor: {
        switch(type) {
            case 0: return "#00d2ff"; // Cyan (Work)
            case 1: return "#00ff88"; // Neon Green (Life)
            case 2: return "#ff0055"; // Neon Pink (Anniversary)
            case 3: return "#ff9500"; // Neon Orange (Health)
            default: return "#ffffff";
        }
    }
    
    // Auto-close timer REMOVED as per user request (Persistence required)
    /*
    Timer {
        id: autoCloseTimer
        interval: 10000 // 10 seconds auto dismiss if not forced
        running: !forceMode && !hoverHandler.hovered
        onTriggered: closeAnim.start()
    }
    */
    
    // Entry Animation
    Component.onCompleted: {
        showAnim.start()
    }
    
    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: mainCard; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: mainCard; property: "x"; from: 50; to: 0; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
    }
    
    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: mainCard; property: "opacity"; to: 0; duration: 300 }
        ScriptAction { script: root.destroy() }
    }
    
    // Main Card Container
    Item {
        id: mainCard
        anchors.fill: parent
        opacity: 0 // Start hidden
        
        // 1. Glass Background
        Rectangle {
            id: bgRect
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(20/255, 30/255, 48/255, 0.85) // Dark semi-transparent
            border.color: Qt.rgba(255, 255, 255, 0.1)
            border.width: 1
            
            // Frosted Glass Simulation (Blur behind is hard in overlay, so we fake it with noise/gradient)
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 8
                radius: 24
                samples: 20
                color: "#80000000"
            }
            
            // Gradient Sheen
            Rectangle {
                anchors.fill: parent
                radius: 16
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(255,255,255,0.05) }
                    GradientStop { position: 0.4; color: "transparent" }
                }
            }
        }
        
        // 2. Glowing Accent Border (Left Side)
        Rectangle {
            width: 4
            height: parent.height - 32
            anchors.left: parent.left
            anchors.leftMargin: 1
            anchors.verticalCenter: parent.verticalCenter
            radius: 2
            color: themeColor
            
            layer.enabled: true
            layer.effect: Glow {
                radius: 8
                samples: 16
                color: themeColor
                spread: 0.5
            }
        }

        // ========================================================================
        // 2.0 Work: Digital Flow / Matrix Rain (Type 0)
        // ========================================================================
        Item {
            anchors.fill: parent
            visible: type === 0
            clip: true
            z: 0
            
            ParticleSystem {
                id: workSys
                anchors.fill: parent
                running: parent.visible
                
                // Digital Bits
                ItemParticle {
                    delegate: Rectangle {
                        width: Math.random() * 4 + 2
                        height: width
                        color: "#00d2ff"
                        opacity: 0.6
                        radius: 1
                    }
                }

                // Horizontal Flow (Data Streams)
                Emitter {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: parent.height
                    emitRate: 20
                    lifeSpan: 2000
                    size: 4
                    velocity: AngleDirection { angle: 0; magnitude: 150; magnitudeVariation: 50 }
                    acceleration: PointDirection { x: 50 }
                }
            }
        }

        // ========================================================================
        // 2.1 Life: Floating Bubbles / Fireflies (Type 1)
        // ========================================================================
        Item {
            anchors.fill: parent
            visible: type === 1
            clip: true
            z: 0
            
            ParticleSystem {
                id: lifeSys
                anchors.fill: parent
                running: parent.visible
                
                ItemParticle {
                    delegate: Rectangle {
                        width: 8; height: 8
                        radius: 4
                        color: "#00ff88"
                        opacity: 0.4
                    }
                }
                
                Emitter {
                    anchors.fill: parent
                    emitRate: 10
                    lifeSpan: 4000
                    size: 8
                    sizeVariation: 4
                    velocity: AngleDirection { angle: -90; angleVariation: 180; magnitude: 10 }
                }
                
                Wander {
                    xVariance: 50
                    yVariance: 50
                    pace: 20
                }
            }
        }

        // ========================================================================
        // 2.2 Anniversary: Celebration Ribbons & Sparkles (Type 2)
        // ========================================================================
        Item {
            anchors.fill: parent
            visible: type === 2
            clip: false 
            z: 0 
            
            ParticleSystem {
                id: particleSys
                anchors.fill: parent
                running: parent.visible
                
                // Confetti Strips
                ItemParticle {
                    id: ribbonParticle
                    groups: ["ribbons"]
                    delegate: Rectangle {
                        width: Math.random() > 0.5 ? 8 : 4
                        height: Math.random() > 0.5 ? 4 : 12 
                        color: {
                            var colors = ["#ff0055", "#ffcc00", "#00d2ff", "#ffffff", "#ff00ff"];
                            return colors[Math.floor(Math.random() * colors.length)];
                        }
                        radius: 2
                        opacity: 0.9
                    }
                }
                
                // Sparkles (New!)
                ItemParticle {
                    groups: ["sparkles"]
                    delegate: Rectangle {
                        width: 3; height: 3
                        color: "#ffffff"
                        opacity: 0
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1; duration: 200 }
                            NumberAnimation { to: 0; duration: 200 }
                        }
                    }
                }
                
                // Ribbon Emitter
                Emitter {
                    group: "ribbons"
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -10
                    width: parent.width
                    height: 20
                    emitRate: 30 
                    lifeSpan: 3500
                    lifeSpanVariation: 500
                    size: 8
                    sizeVariation: 4
                    velocity: AngleDirection { angle: -90; angleVariation: 60; magnitude: 60; magnitudeVariation: 30 }
                    acceleration: PointDirection { y: 30 }
                }
                
                // Sparkle Emitter
                Emitter {
                    group: "sparkles"
                    anchors.fill: parent
                    emitRate: 20
                    lifeSpan: 1000
                    size: 4
                }
                
                Wander {
                    groups: ["ribbons"]
                    xVariance: 20
                    pace: 100
                }
            }
        }

        // ========================================================================
        // 2.3 Health: Vitality Pulse (Type 3)
        // ========================================================================
        Item {
            anchors.fill: parent
            visible: type === 3
            z: -1 // Deep background
            
            // Pulsing Background Gradient
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.8
                radius: width / 2
                color: Qt.rgba(1, 0.5, 0, 0.15) // Orange tint
                
                SequentialAnimation on scale {
                    running: type === 3
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.5; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on opacity {
                    running: type === 3
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.1; duration: 2000; easing.type: Easing.InOutSine }
                }
            }
            
            // Border Breathing
            SequentialAnimation {
                running: type === 3
                loops: Animation.Infinite
                ColorAnimation { target: bgRect; property: "border.color"; from: Qt.rgba(255, 255, 255, 0.1); to: themeColor; duration: 2000; easing.type: Easing.InOutSine }
                ColorAnimation { target: bgRect; property: "border.color"; from: themeColor; to: Qt.rgba(255, 255, 255, 0.1); duration: 2000; easing.type: Easing.InOutSine }
            }
        }
        
        // 3. Content Layout
        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16
            
            // Icon
            Rectangle {
                width: 48; height: 48
                radius: 24
                color: Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.2)
                border.color: Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.5)
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        switch(type) {
                            case 0: return "💼";
                            case 1: return "🏠";
                            case 2: return "🎂";
                            case 3: return "💊";
                            default: return "📅";
                        }
                    }
                    font.pixelSize: 24
                }
                
                // Pulse Animation
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { to: 1.1; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
                }
            }
            
            // Text Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: titleStr
                    color: "#ffffff"
                    font.pixelSize: 18
                    font.bold: true
                    font.family: "Microsoft YaHei UI"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                Text {
                    text: messageStr
                    color: "#d0d0d0"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }
            }
            
            // Actions
            ColumnLayout {
                spacing: 12 // Increased spacing for cleaner look
                
                // Close / Complete ("我知道了")
                Button {
                    id: confirmBtn
                    text: (forceMode && forceDuration > 0) ? forceDuration + "s" : "我知道了"
                    enabled: !(forceMode && forceDuration > 0)
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 36
                    
                    background: Rectangle {
                        radius: 18
                        // Gradient Background for "Extreme Aesthetics"
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: confirmBtn.enabled ? Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.3) : Qt.rgba(1,1,1,0.05) }
                            GradientStop { position: 1.0; color: confirmBtn.enabled ? Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.1) : Qt.rgba(1,1,1,0.02) }
                        }
                        border.color: confirmBtn.enabled ? themeColor : Qt.rgba(255,255,255,0.1)
                        border.width: 1
                        
                        // Glow Effect on Hover
                        layer.enabled: confirmBtn.enabled && confirmBtn.hovered
                        layer.effect: Glow {
                            radius: 8
                            samples: 16
                            color: themeColor
                            spread: 0.3
                        }
                        
                        // Progress Bar for Force Mode
                        Rectangle {
                            visible: forceMode && forceDuration > 0
                            height: parent.height
                            width: parent.width * (forceDuration / 30.0) 
                            color: Qt.rgba(1,1,1,0.1)
                            radius: 18
                        }
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: confirmBtn.enabled ? "#ffffff" : "#808080"
                        font.bold: true
                        font.pixelSize: 13
                        font.family: "Microsoft YaHei UI"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        
                        // Text Shadow
                        style: Text.Outline
                        styleColor: confirmBtn.enabled ? Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.3) : "transparent"
                    }
                    
                    onClicked: {
                        console.log("Dismiss requested");
                        root.dismissRequested()
                    }
                }
                
                // Snooze ("推迟 X 分")
                Button {
                    id: snoozeBtn
                    text: "推迟 " + snoozeMinutes + " 分"
                    visible: !forceMode
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 32
                    
                    background: Rectangle {
                        radius: 16
                        color: snoozeBtn.hovered ? Qt.rgba(255,255,255,0.1) : "transparent"
                        border.color: snoozeBtn.hovered ? "#ffffff" : Qt.rgba(255,255,255,0.3)
                        border.width: 1
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: snoozeBtn.hovered ? "#ffffff" : "#d0d0d0"
                        font.pixelSize: 12
                        font.family: "Microsoft YaHei UI"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    // Mouse Wheel Logic for Snooze Duration
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onWheel: {
                            var delta = wheel.angleDelta.y > 0 ? 1 : -1;
                            var newVal = root.snoozeMinutes + delta;
                            if (newVal < 1) newVal = 1;
                            if (newVal > 10) newVal = 10;
                            root.snoozeMinutes = newVal;
                        }
                        onPressed: mouse.accepted = false // Pass click to Button
                    }
                    
                    onClicked: {
                        console.log("Snoozing for " + root.snoozeMinutes + " minutes");
                        root.snoozeRequested(root.snoozeMinutes)
                        closeAnim.start()
                    }
                    
                    ToolTip {
                        id: snoozeTip
                        visible: snoozeBtn.hovered
                        delay: 500
                        text: "滚动鼠标滚轮调整时间 (1-10分)"
                        
                        contentItem: Row {
                            spacing: 8
                            
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: themeColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: snoozeTip.text
                                font.pixelSize: 12
                                font.family: "Microsoft YaHei"
                                color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        background: Rectangle {
                            color: "#CC1B2A4E"
                            border.color: "#33ffffff"
                            border.width: 1
                            radius: 16
                        }
                        
                        topPadding: 8
                        bottomPadding: 8
                        leftPadding: 12
                        rightPadding: 12
                    }
                }
            }
        }
        
        // Hover Handler to pause auto-close
        HoverHandler {
            id: hoverHandler
        }
        
        // Drag Handler
        MouseArea {
            anchors.fill: parent
            z: -1
            onPressed: root.startSystemMove()
        }
    }
    
    // Force Timer
    Timer {
        interval: 1000
        repeat: true
        running: forceMode && forceDuration > 0
        onTriggered: forceDuration--
    }
}
