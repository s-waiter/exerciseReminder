import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Item {
    id: reportDialog
    anchors.fill: parent
    visible: false
    z: 200

    property color themeColor: "#00d2ff"
    property date currentDate: new Date()
    property int selectedRange: 0 // 0:Day, 1:Week, 2:Month, 3:Custom
    property int selectedMode: 0 // 0:Self, 1:Formal
    
    property date customStartDate: new Date()
    property date customEndDate: new Date()
    property int pickingDateFor: 0 // 0:None, 1:Start, 2:End

    function open() {
        visible = true
        selectedRange = 0
        selectedMode = 0
        customStartDate = new Date()
        customEndDate = new Date()
        generate()
    }

    function close() {
        visible = false
        pickingDateFor = 0
    }

    function generate() {
        var text = ""
        if (selectedRange === 3) {
            var start = new Date(customStartDate)
            start.setHours(0,0,0,0)
            var end = new Date(customEndDate)
            end.setHours(23,59,59,999)
            text = activityLogger.generateReportCustom(start.getTime(), end.getTime(), selectedMode)
        } else {
            text = activityLogger.generateReport(currentDate, selectedRange, selectedMode)
        }
        previewArea.text = text
    }

    // Background Dimmer
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: reportDialog.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: reportDialog.close()
        }
    }

    // Main Dialog Window
    Rectangle {
        id: dialogWindow
        width: 680
        height: 600
        radius: 16
        anchors.centerIn: parent
        
        // Gradient Background
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F01B2A4E" }
            GradientStop { position: 1.0; color: "#F0101828" }
        }
        
        border.color: Qt.rgba(255, 255, 255, 0.1)
        border.width: 1

        // Drop Shadow
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 8
            radius: 24
            samples: 17
            color: "#80000000"
        }

        // Entry Animation
        scale: reportDialog.visible ? 1.0 : 0.95
        opacity: reportDialog.visible ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea { anchors.fill: parent } // Prevent click through

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                
                Rectangle {
                    width: 40; height: 40; radius: 12
                    color: Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.2)
                    Text { 
                        text: "📊"; anchors.centerIn: parent; font.pixelSize: 20 
                    }
                }
                
                ColumnLayout {
                    spacing: 2
                    Text { 
                        text: "自动报表生成器"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text { 
                        text: "基于您的活动数据一键生成专业报表"
                        color: "#AAAAAA"
                        font.pixelSize: 12
                    }
                }
                
                Item { Layout.fillWidth: true } // Spacer
                
                // Close Button
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: closeMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                    Text { text: "✕"; color: "white"; anchors.centerIn: parent }
                    MouseArea {
                        id: closeMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: reportDialog.close()
                    }
                }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.1) }

            // Controls Section
            RowLayout {
                Layout.fillWidth: true
                spacing: 30
                
                // Range Selector
                ColumnLayout {
                    spacing: 8
                    Text { text: "📅 时间范围"; color: "#888888"; font.pixelSize: 12; font.bold: true }
                    
                    Row {
                        spacing: 8
                        Repeater {
                            model: ["今日日报", "本周周报", "本月月报", "自定义"]
                            delegate: Rectangle {
                                width: 80; height: 32; radius: 8
                                color: selectedRange === index ? themeColor : Qt.rgba(1,1,1,0.05)
                                border.color: selectedRange === index ? "transparent" : Qt.rgba(1,1,1,0.1)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: selectedRange === index ? "white" : "#AAAAAA"
                                    font.bold: selectedRange === index
                                    font.pixelSize: 12
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        selectedRange = index
                                        generate()
                                    }
                                }
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                    
                    // Custom Date Pickers
                    RowLayout {
                        visible: selectedRange === 3
                        spacing: 10
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        
                        // Start Date
                        Rectangle {
                            width: 100; height: 28; radius: 6
                            color: Qt.rgba(1,1,1,0.05); border.color: "#444"
                            Text { 
                                anchors.centerIn: parent
                                text: Qt.formatDate(customStartDate, "yyyy-MM-dd")
                                color: "white"; font.pixelSize: 12
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: pickingDateFor = 1
                            }
                        }
                        Text { text: "至"; color: "#888"; font.pixelSize: 12 }
                        // End Date
                        Rectangle {
                            width: 100; height: 28; radius: 6
                            color: Qt.rgba(1,1,1,0.05); border.color: "#444"
                            Text { 
                                anchors.centerIn: parent
                                text: Qt.formatDate(customEndDate, "yyyy-MM-dd")
                                color: "white"; font.pixelSize: 12
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: pickingDateFor = 2
                            }
                        }
                    }
                }

                // Divider
                Rectangle { width: 1; height: 40; color: Qt.rgba(1,1,1,0.1); Layout.alignment: Qt.AlignVCenter }

                // Mode Selector
                ColumnLayout {
                    spacing: 8
                    Text { text: "👁️ 视图模式"; color: "#888888"; font.pixelSize: 12; font.bold: true }
                    
                    Row {
                        spacing: 8
                        Repeater {
                            model: ["全景复盘 (个人)", "职场汇报 (正式)"]
                            delegate: Rectangle {
                                width: 110; height: 32; radius: 8
                                color: selectedMode === index ? themeColor : Qt.rgba(1,1,1,0.05)
                                border.color: selectedMode === index ? "transparent" : Qt.rgba(1,1,1,0.1)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: selectedMode === index ? "white" : "#AAAAAA"
                                    font.bold: selectedMode === index
                                    font.pixelSize: 12
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        selectedMode = index
                                        generate()
                                    }
                                }
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                }
            }

            // Preview Area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.2)
                radius: 12
                border.color: Qt.rgba(1,1,1,0.1)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 0
                    
                    Text { 
                        text: "📋 预览内容"
                        color: "#666666"
                        font.pixelSize: 12
                        Layout.bottomMargin: 8
                    }
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        TextArea {
                            id: previewArea
                            readOnly: true
                            color: "#E0E0E0"
                            font.pixelSize: 13
                            font.family: "Consolas, monospace"
                            wrapMode: Text.Wrap
                            selectByMouse: true
                            background: null
                            selectionColor: Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.4)
                        }
                    }
                }
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                
                Item { Layout.fillWidth: true } // Spacer
                
                // Copy Button
                Rectangle {
                    width: 140; height: 40; radius: 20
                    color: copyMa.pressed ? Qt.darker(themeColor, 1.2) : themeColor
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "📄"; font.pixelSize: 14 }
                        Text { 
                            text: "一键复制"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }
                    
                    MouseArea {
                        id: copyMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            previewArea.selectAll()
                            previewArea.copy()
                            previewArea.deselect()
                            toast.show("已复制到剪贴板 ✅")
                        }
                    }
                    
                    // Hover effect
                    layer.enabled: copyMa.containsMouse
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: 2
                        radius: 8
                        samples: 9
                        color: Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.5)
                    }
                }
            }
        }
        
        // Calendar Popup Overlay
        Rectangle {
            id: calendarOverlay
            anchors.fill: parent
            color: Qt.rgba(0,0,0,0.4)
            visible: pickingDateFor > 0
            
            MouseArea { anchors.fill: parent; onClicked: pickingDateFor = 0 }
            
            CalendarPicker {
                anchors.centerIn: parent
                currentDate: pickingDateFor === 1 ? customStartDate : customEndDate
                selectedDate: currentDate
                
                onDateSelected: {
                    if (pickingDateFor === 1) customStartDate = selectedDate
                    else if (pickingDateFor === 2) customEndDate = selectedDate
                    
                    pickingDateFor = 0
                    generate()
                }
            }
        }
        
        // Internal Toast
        Rectangle {
            id: toast
            width: toastText.implicitWidth + 40
            height: 36
            radius: 18
            color: "#333333"
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 150
            opacity: 0
            z: 100
            
            Text {
                id: toastText
                anchors.centerIn: parent
                color: "white"
                font.bold: true
            }
            
            function show(msg) {
                toastText.text = msg
                toastAnim.restart()
            }
            
            SequentialAnimation {
                id: toastAnim
                NumberAnimation { target: toast; property: "opacity"; to: 1; duration: 200 }
                PauseAnimation { duration: 1500 }
                NumberAnimation { target: toast; property: "opacity"; to: 0; duration: 200 }
            }
        }
    }
}
