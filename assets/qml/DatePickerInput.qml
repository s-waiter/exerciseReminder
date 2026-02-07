import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

Item {
    id: root
    width: 140
    height: 32
    
    property string text: ""
    property date selectedDate: new Date()
    property color primaryColor: "#00d2ff"
    property color textColor: "#d0d0d0"
    property color inputBgColor: Qt.rgba(0, 0, 0, 0.3)
    property string placeholderText: "选择日期"
    
    onTextChanged: {
        if (!text) return
        var parts = text.split("-")
        if (parts.length === 3) {
            var y = parseInt(parts[0])
            var m = parseInt(parts[1]) - 1
            var d = parseInt(parts[2])
            var newDate = new Date(y, m, d)
            if (!isNaN(newDate.getTime()) && newDate.getTime() !== selectedDate.getTime()) {
                selectedDate = newDate
            }
        }
    }
    
    signal datePicked(date date)
    
    Rectangle {
        id: bg
        anchors.fill: parent
        color: inputBgColor
        radius: 8
        border.color: mouseArea.containsMouse || popup.opened ? primaryColor : "transparent"
        border.width: mouseArea.containsMouse || popup.opened ? 1 : 0
        
        layer.enabled: mouseArea.containsMouse || popup.opened
        layer.effect: Glow {
            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.5)
            radius: 8
            samples: 16
        }
        
        Text {
            anchors.centerIn: parent
            text: root.text || root.placeholderText
            color: root.text ? textColor : "#808895"
            font.pixelSize: 14
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.open()
        }
    }
    
    Popup {
        id: popup
        anchors.centerIn: Overlay.overlay
        width: 360
        height: 400
        padding: 0
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        dim: true // Darken background to emphasize modal
        
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
            NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        }
        
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 200 }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.9; duration: 200; easing.type: Easing.InCubic }
        }
        
        background: Rectangle {
            color: "#1B2A4E"
            radius: 12
            border.color: primaryColor
            border.width: 1
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 8
                radius: 24
                samples: 32
                color: "#80000000"
            }
        }
        
        CalendarPicker {
            id: calendar
            anchors.centerIn: parent
            // Ensure properties are passed down
            themeColor: root.primaryColor
            selectedDate: root.selectedDate
            
            onDateSelected: {
                root.selectedDate = selectedDate
                root.text = Qt.formatDate(selectedDate, "yyyy-MM-dd")
                root.datePicked(selectedDate)
                popup.close()
            }
        }
    }
}
