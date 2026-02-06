import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

TextField {
    id: control
    
    property color textColor: "#d0d0d0"
    property color secondaryTextColor: "#808895"
    property color inputBgColor: Qt.rgba(0, 0, 0, 0.3)
    property color primaryColor: "#00d2ff"

    color: textColor
    placeholderTextColor: secondaryTextColor
    selectByMouse: true
    font.pixelSize: 14
    leftPadding: 12
    property bool enableWheel: false

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton // Pass clicks to TextField
        cursorShape: Qt.IBeamCursor
        onWheel: {
            if (!control.enableWheel) return
            
            var delta = wheel.angleDelta.y > 0 ? 1 : -1
            var val = parseInt(control.text)
            var min = 0
            var max = 9999
            
            // Try to get bounds from validator
            if (control.validator) {
                if (control.validator.bottom !== undefined) min = control.validator.bottom
                if (control.validator.top !== undefined) max = control.validator.top
            }
            
            if (isNaN(val)) {
                val = (delta > 0) ? min : max
            } else {
                val += delta
            }
            
            if (val < min) val = min
            if (val > max) val = max
            
            control.text = val.toString()
        }
    }

    background: Rectangle {
        color: inputBgColor
        radius: 8
        border.color: control.activeFocus ? primaryColor : "transparent"
        border.width: control.activeFocus ? 1 : 0
        
        // Cyberpunk Glow Effect
        layer.enabled: control.activeFocus
        layer.effect: Glow {
            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.5)
            radius: 8
            samples: 16
        }
    }
}
