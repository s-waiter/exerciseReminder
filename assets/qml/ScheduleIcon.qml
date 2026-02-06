import QtQuick 2.15

Item {
    property int type: -1
    property int size: 24
    property color color: "white"
    
    implicitWidth: size
    implicitHeight: size
    
    Text {
        anchors.centerIn: parent
        font.pixelSize: parent.size
        color: parent.color
        text: {
            switch(parent.type) {
                case 0: return "💼"
                case 1: return "🏠"
                case 2: return "🎂"
                case 3: return "💊"
                default: return "📅"
            }
        }
    }
}
