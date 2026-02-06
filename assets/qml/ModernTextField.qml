import QtQuick 2.15
import QtQuick.Controls 2.15

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
    background: Rectangle {
        color: inputBgColor
        radius: 8
        border.color: control.activeFocus ? primaryColor : "transparent"
    }
}
