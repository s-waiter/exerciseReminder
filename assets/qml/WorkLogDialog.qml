import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Item {
    id: workLogOverlay
    anchors.fill: parent
    visible: false
    z: 200

    property int activityId: -1
    property string timeRangeStr: ""
    property string formalContent: ""
    property string learningContent: ""
    property string personalContent: ""
    
    // Theme Colors
    property color themeColor: "#00d2ff"
    property color colorFormal: "#00d2ff"   // Blue
    property color colorLearning: "#00ff88" // Green
    property color colorPersonal: "#ffbf00" // Yellow
    property color colorBgStart: "#F01B2A4E"
    property color colorBgEnd: "#F016203A"

    signal saved(int id, string content, int type)

    function open(id, range, content, type) {
        activityId = id
        timeRangeStr = range
        
        // Parse existing content (JSON or Plain)
        formalContent = ""
        learningContent = ""
        personalContent = ""
        
        if (content.trim().indexOf("{") === 0) {
            try {
                var json = JSON.parse(content)
                formalContent = json.formal || ""
                learningContent = json.learning || ""
                personalContent = json.personal || ""
            } catch (e) {
                console.log("JSON parse error:", e)
                formalContent = content // Fallback
            }
        } else {
            // Legacy: Assign to based on type
            if (type === 1) learningContent = content
            else if (type === 2) personalContent = content
            else formalContent = content
        }

        // Default tab
        tabBar.currentIndex = 0
        visible = true
    }

    function close() {
        visible = false
    }

    // 1. Background Dimmer with Blur
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        MouseArea {
            anchors.fill: parent
            onClicked: workLogOverlay.close()
        }
    }

    // 2. Main Dialog Card
    Rectangle {
        id: dialog
        width: 500
        height: 450
        radius: 20
        anchors.centerIn: parent
        
        // Gradient Background
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2B3245" }
            GradientStop { position: 1.0; color: "#1E2330" }
        }
        
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

        // Shadow
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            color: "#80000000"
            radius: 20
            samples: 25
            verticalOffset: 10
        }

        // Entry Animation
        transform: Scale {
            id: dialogScale
            origin.x: dialog.width / 2
            origin.y: dialog.height / 2
            xScale: visible ? 1.0 : 0.9
            yScale: visible ? 1.0 : 0.9
            Behavior on xScale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on yScale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea { anchors.fill: parent } // Block clicks

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            // Header
            ColumnLayout {
                spacing: 5
                Layout.alignment: Qt.AlignHCenter
                
                Text {
                    text: "工时内容录入"
                    color: "white"
                    font.pixelSize: 22
                    font.bold: true
                    font.family: "Microsoft YaHei UI"
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Text {
                    text: timeRangeStr
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Custom Tab Bar
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: Qt.rgba(0, 0, 0, 0.2)
                radius: 20
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    Repeater {
                        id: tabBar
                        model: [
                            { text: "正式工作", color: colorFormal, icon: "🔵" },
                            { text: "学习成长", color: colorLearning, icon: "🟢" },
                            { text: "私人事务", color: colorPersonal, icon: "🟡" }
                        ]
                        
                        property int currentIndex: 0
                        
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: tabBar.currentIndex === index ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.2) : "transparent"
                            radius: 20
                            
                            // Animated transition
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: modelData.icon; font.pixelSize: 12 }
                                Text {
                                    text: modelData.text
                                    color: tabBar.currentIndex === index ? modelData.color : "#888888"
                                    font.bold: tabBar.currentIndex === index
                                    font.pixelSize: 14
                                }
                            }
                            
                            // Indicator Dot if content exists
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                color: modelData.color
                                anchors.top: parent.top; anchors.topMargin: 8
                                anchors.right: parent.right; anchors.rightMargin: 15
                                visible: {
                                    if (index === 0) return workLogOverlay.formalContent.length > 0
                                    if (index === 1) return workLogOverlay.learningContent.length > 0
                                    if (index === 2) return workLogOverlay.personalContent.length > 0
                                    return false
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tabBar.currentIndex = index
                            }
                        }
                    }
                }
            }

            // Content Area (Stack Layout)
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex
                
                // 1. Formal
                TextAreaInput {
                    placeholderText: "在此记录正式工作内容..."
                    text: workLogOverlay.formalContent
                    onTextChanged: workLogOverlay.formalContent = text
                    accentColor: colorFormal
                }
                
                // 2. Learning
                TextAreaInput {
                    placeholderText: "在此记录学习成长内容..."
                    text: workLogOverlay.learningContent
                    onTextChanged: workLogOverlay.learningContent = text
                    accentColor: colorLearning
                }
                
                // 3. Personal
                TextAreaInput {
                    placeholderText: "在此记录私人事务内容..."
                    text: workLogOverlay.personalContent
                    onTextChanged: workLogOverlay.personalContent = text
                    accentColor: colorPersonal
                }
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                
                Button {
                    text: "取消"
                    Layout.fillWidth: true
                    flat: true
                    background: Rectangle {
                        color: parent.down ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        radius: 12
                        border.color: "#555555"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#AAAAAA"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 15
                    }
                    onClicked: workLogOverlay.close()
                }

                Button {
                    text: "保存所有更改"
                    Layout.fillWidth: true
                    flat: true
                    background: LinearGradient {
                        start: Qt.point(0, 0)
                        end: Qt.point(width, 0)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#00d2ff" }
                            GradientStop { position: 1.0; color: "#3a7bd5" }
                        }
                        
                        Rectangle { // Mask for radius
                            anchors.fill: parent
                            color: "transparent"
                            radius: 12
                            border.color: Qt.rgba(1,1,1,0.2)
                        }
                        
                        opacity: parent.down ? 0.8 : 1.0
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        style: Text.Outline
                        styleColor: "#33000000"
                    }
                    onClicked: {
                        // Construct JSON
                        var data = {
                            "formal": workLogOverlay.formalContent,
                            "learning": workLogOverlay.learningContent,
                            "personal": workLogOverlay.personalContent
                        }
                        var jsonStr = JSON.stringify(data)
                        
                        // Calculate primary type (bitmask or dominant)
                        // Just use 0 (Formal) as default, or use bitmask if we change schema
                        // For now, pass 0. The report generator parses JSON anyway.
                        workLogOverlay.saved(activityId, jsonStr, 0)
                        workLogOverlay.close()
                    }
                }
            }
        }
    }

    // Helper Component for TextArea
    component TextAreaInput : Rectangle {
        property alias text: area.text
        property alias placeholderText: area.placeholderText
        property color accentColor: "#ffffff"
        
        color: Qt.rgba(0, 0, 0, 0.3)
        radius: 12
        border.color: area.activeFocus ? accentColor : "transparent"
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 200 } }
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: 10
            TextArea {
                id: area
                color: "white"
                font.pixelSize: 15
                wrapMode: Text.Wrap
                selectByMouse: true
                background: null
                placeholderTextColor: "#666666"
                selectionColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4)
            }
        }
    }
}
