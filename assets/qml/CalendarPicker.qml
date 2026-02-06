import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Item {
    id: calendarPicker
    width: 340
    height: 380
    
    // Signals
    signal dateSelected(date selectedDate)
    signal monthChanged(int year, int month)
    
    // Properties
    property date currentDate: new Date()
    property date selectedDate: new Date()
    property color themeColor: "#00d2ff"
    property color backgroundColor: "#1B2A4E"
    property color textColor: "#FFFFFF"
    property var activeDays: [] // Array of day numbers (int) that have data
    
    // Internal
    property int currentMonth: currentDate.getMonth()
    property int currentYear: currentDate.getFullYear()

    onCurrentDateChanged: {
        // Only update if actually different to avoid loops
        if (currentDate.getMonth() !== currentMonth || currentDate.getFullYear() !== currentYear) {
            currentMonth = currentDate.getMonth()
            currentYear = currentDate.getFullYear()
            refreshCalendar()
        }
    }

    onSelectedDateChanged: {
        // When selected date changes externally, update the view to show that month
        if (selectedDate.getFullYear() !== currentYear || selectedDate.getMonth() !== currentMonth) {
            currentMonth = selectedDate.getMonth()
            currentYear = selectedDate.getFullYear()
            // Don't modify currentDate here to avoid circular binding
            refreshCalendar()
        } else {
             // Just refresh grid highlight
             refreshCalendar()
        }
    }
    
    function setDate(date) {
        // This function might be redundant if we bind to currentDate, 
        // but kept for imperative usage
        currentDate = date
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
        
        // Notify parent to fetch data
        monthChanged(currentYear, currentMonth)
    }
    
    function previousMonth() {
        if (currentMonth === 0) {
            currentMonth = 11
            currentYear--
        } else {
            currentMonth--
        }
        refreshCalendar()
    }
    
    function nextMonth() {
        if (currentMonth === 11) {
            currentMonth = 0
            currentYear++
        } else {
            currentMonth++
        }
        refreshCalendar()
    }
    
    Component.onCompleted: refreshCalendar()
    
    // Main Background
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        radius: 16
        border.color: Qt.rgba(1,1,1,0.1)
        border.width: 1
        
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            color: "#80000000"
            radius: 20
            samples: 25
            verticalOffset: 5
        }
        
        // Mouse Wheel Handler for Month Navigation
        MouseArea {
            anchors.fill: parent
            z: 0 // Behind buttons but covers grid
            propagateComposedEvents: true
            onWheel: {
                if (wheel.angleDelta.y > 0) {
                    previousMonth()
                } else {
                    nextMonth()
                }
            }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                
                // Prev Month
                Button {
                    text: "<"
                    flat: true
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    
                    background: Rectangle {
                        color: parent.hovered ? Qt.rgba(1,1,1,0.1) : "transparent"
                        radius: 18
                    }
                    contentItem: Text { 
                        text: "◀"
                        color: textColor
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter 
                        opacity: 0.8
                    }
                    onClicked: previousMonth()
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
                    font.pixelSize: 18
                    font.bold: true
                    font.family: "Microsoft YaHei UI"
                }
                
                // Next Month
                Button {
                    text: ">"
                    flat: true
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    
                    background: Rectangle {
                        color: parent.hovered ? Qt.rgba(1,1,1,0.1) : "transparent"
                        radius: 18
                    }
                    contentItem: Text { 
                        text: "▶" 
                        color: textColor 
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter 
                        verticalAlignment: Text.AlignVCenter
                        opacity: 0.8
                    }
                    onClicked: nextMonth()
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
                            color: Qt.rgba(255, 255, 255, 0.5)
                            font.pixelSize: 13
                            font.bold: true
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
                    
                    property var dateObj: model.date
                    
                    property bool isSelected: {
                        if (!dateObj || !selectedDate) return false
                        return dateObj.getDate() === selectedDate.getDate() && 
                               dateObj.getMonth() === selectedDate.getMonth() && 
                               dateObj.getFullYear() === selectedDate.getFullYear()
                    }
                    
                    property bool isToday: {
                        var today = new Date()
                        if (!dateObj) return false
                        return dateObj.getDate() === today.getDate() && 
                               dateObj.getMonth() === today.getMonth() && 
                               dateObj.getFullYear() === today.getFullYear()
                    }
                    
                    property bool hasData: {
                        if (!model.isCurrentMonth) return false
                        if (!calendarPicker.activeDays) return false
                        for(var i=0; i<calendarPicker.activeDays.length; i++) {
                            if (calendarPicker.activeDays[i] === model.day) return true
                        }
                        return false
                    }

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        anchors.centerIn: parent
                        
                        // Selection Background
                        color: isSelected ? themeColor : "transparent"
                        
                        // Today Border
                        border.color: isToday && !isSelected ? themeColor : "transparent"
                        border.width: 1
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        // Text
                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: isSelected ? "white" : (model.isCurrentMonth ? textColor : Qt.rgba(255,255,255,0.3))
                            font.bold: isSelected || isToday
                            font.pixelSize: 14
                        }
                        
                        // Data Indicator Dot
                        Rectangle {
                            width: 4
                            height: 4
                            radius: 2
                            color: isSelected ? "white" : themeColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            visible: hasData
                            opacity: isSelected ? 0.8 : 1.0
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dateSelected(model.date)
                            }
                        }
                    }
                }
            }
        }
    }
}
