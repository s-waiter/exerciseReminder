import QtQuick 2.15
import QtQuick.Controls 2.15

TextInput {
    id: control
    property int max: 59
    property color textColor: "#d0d0d0"
    
    signal next()
    
    text: "00"
    color: textColor
    font.pixelSize: 32
    font.family: "Consolas"
    font.bold: true
    horizontalAlignment: TextInput.AlignHCenter
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true
    validator: IntValidator { bottom: 0; top: max }
    
    onTextChanged: {
        var val = parseInt(text)
        if (!isNaN(val) && val > max) text = max.toString()
        if (text.length === 2 && !isNaN(val)) next()
    }
    
    onEditingFinished: {
        if (text.length === 1) text = "0" + text
        if (text.length === 0) text = "00"
    }
}
