import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: root
    visible: true
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool | Qt.WindowDoesNotAcceptFocus
    color: "transparent"
    
    // Properties to be set by the creator
    property string text: ""
    property color textColor: "#FFFFFF" 
    property int fontSize: 24
    property int duration: 8000
    property real screenX: 0
    property real screenWidth: Screen.width
    property real yPos: 0
    
    // Signals
    signal finished() // Animation natural end
    signal requestRecycle() // Explicit request to be recycled (e.g. clicked)
    signal requestEffect(real globalX, real globalY, color c) // Request visual effect
    
    Component.onCompleted: {
        root.lower()
        startAnimation()
    }
    
    x: screenX + screenWidth
    y: yPos
    width: textItem.implicitWidth + 10 
    height: textItem.implicitHeight + 10
    
    // Main Content
    Text {
        id: textItem
        text: root.text
        // Subtle fill (very transparent theme color)
        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.15)
        font.family: "Microsoft YaHei UI"
        font.pixelSize: root.fontSize
        font.bold: true
        font.letterSpacing: 2
        anchors.centerIn: parent
        style: Text.Outline
        // Darker outline for contrast (Deepen the theme color)
        styleColor: Qt.darker(root.textColor, 1.5)
        
        // Optimization: Cache as texture to avoid re-rasterization during movement
        layer.enabled: true
        layer.smooth: true
    }
    
    // Interaction
    MouseArea {
        id: mouseArea
        // Bind to textItem size to ensure click-through works outside text
        anchors.centerIn: parent
        width: textItem.implicitWidth
        height: textItem.implicitHeight
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            // Calculate global center position for effect
            var globalX = root.x + width/2
            var globalY = root.y + height/2
            
            // Request effect and recycle
            root.requestEffect(globalX, globalY, root.textColor)
            root.visible = false
            root.requestRecycle()
        }
    }
    
    // Watchdog Timer (Keep as failsafe, but now it recycles instead of destroys)
    Timer {
        id: watchdogTimer
        interval: 15000 
        running: false // Controlled by restart()
        repeat: false
        onTriggered: {
            if (root.visible) {
                root.visible = false
                root.requestRecycle()
            }
        }
    }
    
    // Movement Animation
    // Reverted to NumberAnimation because XAnimator does not support Window targets.
    // The previous stuttering was primarily caused by the error logging which is now fixed.
    NumberAnimation {
        id: moveAnim
        target: root
        property: "x"
        from: root.screenX + root.screenWidth
        to: root.screenX - root.width
        duration: root.duration
        easing.type: Easing.Linear
        onFinished: {
            if (root.visible) {
                root.visible = false
                root.finished()
            }
        }
    }
    
    function startAnimation() {
        moveAnim.from = root.screenX + root.screenWidth
        moveAnim.to = root.screenX - root.width
        moveAnim.duration = root.duration
        moveAnim.start()
        watchdogTimer.interval = root.duration + 2000
        watchdogTimer.restart()
    }
    
    // Method to reset and restart (for object pooling)
    function restart(newText, newY, newDuration, newColor, newSize, newScreenX, newScreenWidth) {
        // Stop current
        moveAnim.stop()
        watchdogTimer.stop()
        
        // Update properties
        root.text = newText
        root.yPos = newY
        root.y = newY // Apply immediately
        root.duration = newDuration
        root.textColor = newColor
        root.fontSize = newSize
        root.screenX = newScreenX
        root.screenWidth = newScreenWidth
        
        // Reset visibility
        root.visible = true
        root.lower()
        
        // Start
        startAnimation()
    }
}
