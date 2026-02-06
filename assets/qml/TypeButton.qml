import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: control
    property string text
    property int type
    property bool selected
    property color color: "white"
    property color secondaryTextColor: "#808895"
    property color borderColor: Qt.rgba(255, 255, 255, 0.05)
    
    signal clicked()
    
    implicitWidth: 60
    implicitHeight: 32
    
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: parent.selected ? Qt.rgba(parent.color.r, parent.color.g, parent.color.b, 0.2) : "transparent"
        border.color: parent.selected ? parent.color : borderColor
    }
    Text {
        anchors.centerIn: parent
        text: parent.text
        color: parent.selected ? parent.color : secondaryTextColor
        font.bold: parent.selected
    }
    MouseArea { 
        anchors.fill: parent
        onClicked: parent.clicked()
        cursorShape: Qt.PointingHandCursor 
    }
}
