import QtQuick 2.15
import QtQuick.Controls 2.15

TextInput {
    id: control
    property int max: 59
    property color textColor: "#d0d0d0"
    
    // Signals
    signal next()

    // Internal Properties for Aesthetics
    property color primaryColor: "#00d2ff"

    text: "00"
    color: textColor
    font.pixelSize: 32
    font.family: "Consolas"
    font.bold: true
    horizontalAlignment: TextInput.AlignHCenter
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true
    validator: IntValidator { bottom: 0; top: max }
    
    // Background Glow Effect (via parent Rectangle usually, but we can enhance here if needed)
    // For now, relies on parent Rectangle logic in ScheduleListWindow

    onTextChanged: {
        var val = parseInt(text)
        if (!isNaN(val) && val > max) text = max.toString()
        if (text.length === 2 && !isNaN(val)) next()
    }
    
    onEditingFinished: {
        if (text.length === 1) text = "0" + text
        if (text.length === 0) text = "00"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        propagateComposedEvents: true
        onWheel: {
            var delta = wheel.angleDelta.y > 0 ? 1 : -1
            var val = parseInt(control.text)
            if (isNaN(val)) val = 0
            val += delta
            if (val < 0) val = control.max
            if (val > control.max) val = 0
            control.text = (val < 10 ? "0" : "") + val
        }
        onPressed: mouse.accepted = false // Let TextInput handle focus/selection
    }
}
