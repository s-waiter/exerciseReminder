import QtQuick 2.15
import QtQuick.Controls 2.15

ComboBox {
    id: control
    
    property color primaryColor: "#00d2ff"
    property color textColor: "#d0d0d0"
    property color bgColor: Qt.rgba(0, 0, 0, 0.3)
    property color popupBgColor: "#141E30" // Darker than main bg
    
    delegate: ItemDelegate {
        width: control.width
        contentItem: Text {
            text: modelData
            color: hovered ? primaryColor : textColor
            font: control.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: hovered ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1) : "transparent"
        }
        highlighted: control.highlightedIndex === index
    }

    indicator: Canvas {
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 12
        height: 8
        contextType: "2d"

        Connections {
            target: control
            function onPressedChanged() { control.indicator.requestPaint() }
        }

        onPaint: {
            context.reset()
            context.moveTo(0, 0)
            context.lineTo(width, 0)
            context.lineTo(width / 2, height)
            context.closePath()
            context.fillStyle = control.pressed ? primaryColor : textColor
            context.fill()
        }
    }

    contentItem: Text {
        leftPadding: 12
        rightPadding: control.indicator.width + control.spacing

        text: control.displayText
        font: control.font
        color: control.pressed ? primaryColor : textColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: 40
        color: bgColor
        border.color: control.activeFocus ? primaryColor : "transparent"
        radius: 8
    }

    popup: Popup {
        y: control.height - 1
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 1
        
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: popupBgColor
            border.color: Qt.rgba(255, 255, 255, 0.1)
            radius: 8
        }
    }
}
