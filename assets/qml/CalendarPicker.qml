import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Item {
    id: calendarPicker
    width: 320
    height: 360
    
    // Signals
    signal dateSelected(date selectedDate)
    
    // Properties
    property date currentDate: new Date()
    property date selectedDate: new Date()
    property color themeColor: "#00d2ff"
    property color backgroundColor: "#1B2A4E"
    property color textColor: "#FFFFFF"
    
    // Internal
    property int currentMonth: currentDate.getMonth()
    property int currentYear: currentDate.getFullYear()
    
    function setDate(date) {
        selectedDate = date
        currentMonth = date.getMonth()
        currentYear = date.getFullYear()
        refreshCalendar()
    }
    
    function refreshCalendar() {
        gridModel.clear()
        
        var firstDay = new Date(currentYear, currentMonth, 1)
        var startingDay = firstDay.getDay() // 0 is Sunday
        var daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate()
        
        // Previous month padding
        var prevMonthDays = new Date(currentYear, currentMonth, 0).getDate()
        for (var i = 0; i < startingDay; i++) {
            gridModel.append({
                "day": prevMonthDays - startingDay + i + 1,
                "isCurrentMonth": false,
                "date": new Date(currentYear, currentMonth - 1, prevMonthDays - startingDay + i + 1)
            })
        }
        
        // Current month
        for (var i = 1; i <= daysInMonth; i++) {
            gridModel.append({
                "day": i,
                "isCurrentMonth": true,
                "date": new Date(currentYear, currentMonth, i)
            })
        }
        
        // Next month padding
        var totalSlots = 42 // 6 rows * 7 cols
        var currentSlots = startingDay + daysInMonth
        for (var i = 1; i <= (totalSlots - currentSlots); i++) {
            gridModel.append({
                "day": i,
                "isCurrentMonth": false,
                "date": new Date(currentYear, currentMonth + 1, i)
            })
        }
    }
    
    Component.onCompleted: refreshCalendar()
    
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        radius: 12
        border.color: Qt.rgba(1,1,1,0.1)
        
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            color: "#80000000"
            radius: 16
            samples: 17
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                
                // Prev Month
                Button {
                    text: "<"
                    flat: true
                    Layout.preferredWidth: 30
                    contentItem: Text { text: "<"; color: textColor; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: parent.pressed ? Qt.rgba(1,1,1,0.1) : "transparent"; radius: 4 }
                    onClicked: {
                        if (currentMonth === 0) {
                            currentMonth = 11
                            currentYear--
                        } else {
                            currentMonth--
                        }
                        refreshCalendar()
                    }
                }
                
                // Month Year Label
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        var months = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
                        return currentYear + "年 " + months[currentMonth]
                    }
                    color: textColor
                    font.pixelSize: 16
                    font.bold: true
                }
                
                // Next Month
                Button {
                    text: ">"
                    flat: true
                    Layout.preferredWidth: 30
                    contentItem: Text { text: ">"; color: textColor; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: parent.pressed ? Qt.rgba(1,1,1,0.1) : "transparent"; radius: 4 }
                    onClicked: {
                        if (currentMonth === 11) {
                            currentMonth = 0
                            currentYear++
                        } else {
                            currentMonth++
                        }
                        refreshCalendar()
                    }
                }
            }
            
            // Days Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: ["日", "一", "二", "三", "四", "五", "六"]
                    delegate: Item {
                        Layout.fillWidth: true
                        height: 30
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "#888888"
                            font.pixelSize: 12
                        }
                    }
                }
            }
            
            // Grid
            GridView {
                id: calendarGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / 7
                cellHeight: height / 6
                interactive: false
                
                model: ListModel { id: gridModel }
                
                delegate: Item {
                    width: calendarGrid.cellWidth
                    height: calendarGrid.cellHeight
                    
                    property bool isSelected: {
                        return model.date.getDate() === selectedDate.getDate() && 
                               model.date.getMonth() === selectedDate.getMonth() && 
                               model.date.getFullYear() === selectedDate.getFullYear()
                    }
                    
                    property bool isToday: {
                        var today = new Date()
                        return model.date.getDate() === today.getDate() && 
                               model.date.getMonth() === today.getMonth() && 
                               model.date.getFullYear() === today.getFullYear()
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        anchors.centerIn: parent
                        color: isSelected ? themeColor : (isToday ? Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.2) : "transparent")
                        border.color: isToday && !isSelected ? themeColor : "transparent"
                        border.width: 1
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: isSelected ? "white" : (model.isCurrentMonth ? textColor : "#666666")
                            font.bold: isSelected || isToday
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selectedDate = model.date
                            dateSelected(selectedDate)
                            calendarGrid.forceLayout()
                        }
                    }
                }
            }
        }
    }
}
