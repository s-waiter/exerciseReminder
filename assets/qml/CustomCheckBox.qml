import QtQuick 2.15
import QtQuick.Controls 2.15

CheckBox {
    id: control
    
    property color checkedColor: "#00d2ff"
    property color uncheckedColor: "#808895"
    property color textColor: "#d0d0d0"

    indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 6
        color: "transparent"
        border.color: control.checked ? checkedColor : uncheckedColor
        border.width: 2

        Rectangle {
            width: 10
            height: 10
            anchors.centerIn: parent
            radius: 3
            color: checkedColor
            visible: control.checked
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: textColor
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + 12
    }
}
