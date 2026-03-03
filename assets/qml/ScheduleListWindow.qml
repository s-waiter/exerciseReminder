import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import QtQuick.Window 2.15

Window {
    id: root
    
    // ========================================================================
    // Dynamic Layout Configuration
    // ========================================================================
    property int mainViewWidth: 1000  // Fixed width for the Reminder Interface
    property int panelWidth: 450      // Fixed width for the Create Reminder Interface
    
    // Window width adapts dynamically: Base Width + (Panel Width if Open)
    width: mainViewWidth + (isCreatePanelOpen ? panelWidth : 0)
    height: 720
    visible: false
    title: "提醒"

    // Auto-center with slight left offset when shown
    onVisibleChanged: {
        if (visible) {
            // Get screen geometry at cursor position
            // This ensures window appears on the correct monitor
            var geo = windowUtils.getScreenGeometryAtCursor()
            
            if (geo) {
                var availW = geo.width
                var availH = geo.height
                var startX = geo.x
                var startY = geo.y
                
                // Calculate centered position
                // Note: width is dynamic, so we use current width
                var centerX = startX + (availW - width) / 2
                var centerY = startY + (availH - height) / 2
                
                // Apply slight offset to the left (e.g., 100px)
                // This makes the "Reminder" window distinct from "Activity" window
                x = centerX - 100
                y = centerY
            } else {
                // Fallback to primary screen center with offset
                x = (Screen.width - width) / 2 - 100
                y = (Screen.height - height) / 2
            }
            requestActivate()
        }
    }
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent"

    // Smooth Animation for Window Resizing
    Behavior on width { 
        NumberAnimation { 
            duration: 400 
            easing.type: Easing.OutCubic 
        } 
    }

    // Key Handling
    Item {
        focus: true
        Keys.onEscapePressed: root.close()
    }

    // ========================================================================
    // Theme System (Premium Dark Sci-Fi - Warm Edition)
    // ========================================================================
    property color primaryColor: "#00d2ff" // Cyan (Work)
    property color accentColor: "#00ff88"  // Neon Green (Life)
    property color dangerColor: "#ff3b30"  // Red (Anniversary)
    property color healthColor: "#FF9500"  // Orange (Health)
    
    // Backgrounds - Adjusted for "Time Footprints" Unification
    property color windowBgStart: "#F21B2A4E" // Deep Blue (Unified with ~95% Opacity)
    property color windowBgEnd: "#F21B2A4E"   // Solid Deep Blue (Unified with ~95% Opacity)
    property color sidebarColor: Qt.rgba(0, 0, 0, 0.2)
    property color contentColor: "transparent"
    
    // Components
    property color cardBgColor: Qt.rgba(20/255, 30/255, 48/255, 0.6) // Darker background for eye comfort
    property color cardActiveColor: Qt.rgba(0, 210, 255, 0.1)
    property color inputBgColor: Qt.rgba(0, 0, 0, 0.3)
    
    property color textColor: "#d0d0d0" // Slightly dimmed text
    property color secondaryTextColor: "#808895"
    property color borderColor: Qt.rgba(255, 255, 255, 0.05)

    // State
    property int filterType: -1
    property string currentId: ""
    property bool isEditMode: false
    property bool isCreatePanelOpen: false // Controls the Side Panel
    property var editingData: null // Store original data for updates

    // Filter Logic
    property var filteredSchedules: {
        var list = scheduleManager.schedules
        if (filterType === -1) return list
        var res = []
        for(var i=0; i<list.length; i++) {
            if(list[i].type === filterType) res.push(list[i])
        }
        return res
    }

    function getCount(type) {
        var list = scheduleManager.schedules
        if (type === -1) return list.length
        var c = 0
        for(var i=0; i<list.length; i++) {
            if(list[i].type === type) c++
        }
        return c
    }

    // ========================================================================
    // Background & Window Frame
    // ========================================================================
    Rectangle {
        id: mainBackground
        anchors.fill: parent
        anchors.margins: 10
        radius: 16
        clip: true
        
        // Window Dragging Area (Global)
        MouseArea {
            anchors.fill: parent
            z: -1 // Ensure it's behind interactive elements
            onPressed: root.startSystemMove()
        }
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: windowBgStart }
            GradientStop { position: 1.0; color: windowBgEnd }
        }
        
        border.color: Qt.rgba(255, 255, 255, 0.08)
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 10
            radius: 30
            samples: 20
            color: "#80000000"
        }

        // Top Highlight
        Rectangle {
            width: parent.width; height: 1
            color: Qt.rgba(255, 255, 255, 0.1)
            anchors.top: parent.top; anchors.topMargin: 1; radius: 16
        }

        // ====================================================================
        // Split View Layout
        // ====================================================================
        Row {
            anchors.fill: parent
            
            // 1. Left Side: Main Content (Schedule List) - Fixed Width
            // This ensures the "Reminder Interface" never shrinks.
            Item {
                width: mainViewWidth
                height: parent.height
                
                // Content Container with Scale Effect (Optional aesthetic touch)
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    
                    // Push Back Effect: Scales down slightly when panel is open, 
                    // but the CONTAINER width remains 1000, so no layout reflow occurs.
                    scale: isCreatePanelOpen ? 0.95 : 1.0
                    opacity: isCreatePanelOpen ? 0.8 : 1.0
                    
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 400 } }
                    
                    // Inner content (Header + Grid)
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        // Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            // Icon/Title
                            Rectangle {
                                width: 40; height: 40; radius: 12
                                color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)
                                Text { text: "📅"; anchors.centerIn: parent; font.pixelSize: 20 }
                            }
                            Text {
                                text: "提醒"
                                font.pixelSize: 28
                                font.bold: true
                                color: textColor
                                font.family: "Microsoft YaHei UI"
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            // Filter Tabs
                            RowLayout {
                                spacing: 4
                                Repeater {
                                    model: ["全部", "工作", "生活", "纪念", "健康"]
                                    Rectangle {
                                        property color currentColor: root.getCardColor(index - 1)
                                        property bool isSelected: (index - 1) === filterType

                                        width: 60 + (countText.width > 0 ? 10 : 0); height: 32; radius: 16
                                        color: isSelected ? Qt.rgba(currentColor.r, currentColor.g, currentColor.b, 0.2) : "transparent"
                                        border.color: isSelected ? currentColor : borderColor
                                        
                                        // Levitation Effect on Selection
                                        transform: Translate {
                                            y: isSelected ? -2 : 0
                                            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                        }

                                        Text { 
                                            id: countText
                                            text: modelData + " (" + getCount(index - 1) + ")"
                                            anchors.centerIn: parent
                                            color: parent.isSelected ? parent.currentColor : secondaryTextColor 
                                            font.bold: parent.isSelected
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: filterType = index - 1
                                        }
                                    }
                                }
                            }
                            
                            // Add Button
                            Button {
                                id: createBtn
                                text: "+ 新建提醒"
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 40
                                
                                // Levitation Effect on Hover
                                transform: Translate {
                                    y: createBtn.hovered ? -4 : 0
                                    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                }

                                background: Rectangle {
                                    gradient: Gradient { GradientStop { position: 0.0; color: primaryColor } GradientStop { position: 1.0; color: "#007acc" } }
                                    radius: 20
                                    layer.enabled: true
                                    layer.effect: Glow { 
                                        color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.4)
                                        radius: createBtn.hovered ? 15 : 10 
                                        samples: 10 
                                        Behavior on radius { NumberAnimation { duration: 200 } }
                                    }
                                }
                                contentItem: Text { text: parent.text; color: "#141E30"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: openCreate()
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
                            }
                            
                            // Close Button
                            Text {
                                text: "×"
                                font.pixelSize: 32
                                color: secondaryTextColor
                                
                                // Levitation Effect on Hover
                                transform: Translate {
                                    y: closeBtnMouse.containsMouse ? -2 : 0
                                    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    id: closeBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.close()
                                }
                            }
                        }
                        
                        // Empty State
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: gridView.count === 0
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 16
                                Text { text: "📭"; font.pixelSize: 64; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                                Text { 
                                    text: "暂无提醒事项"
                                    color: secondaryTextColor
                                    font.pixelSize: 18
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Button {
                                    text: "创建第一个提醒"
                                    Layout.alignment: Qt.AlignHCenter
                                    background: Rectangle { color: "transparent"; border.color: primaryColor; radius: 20 }
                                    contentItem: Text { text: parent.text; color: primaryColor; padding: 10 }
                                    onClicked: openCreate()
                                }
                            }
                        }

                        // Grid List
                        GridView {
                            id: gridView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: count > 0
                            cellWidth: 320
                            cellHeight: 180
                            clip: true
                            
                            model: filteredSchedules
                            
                            delegate: Loader {
                                width: gridView.cellWidth
                                height: gridView.cellHeight
                                active: true // Filter handled by model
                                visible: true
                                
                                sourceComponent: Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    radius: 16
                                    color: cardBgColor
                                    border.color: hoverHandler.hovered ? Qt.rgba(root.getCardColor(modelData.type).r, root.getCardColor(modelData.type).g, root.getCardColor(modelData.type).b, 0.5) : borderColor
                                    
                                    HoverHandler { id: hoverHandler }
                                    
                                    // Glow Effect on Hover
                                    layer.enabled: hoverHandler.hovered
                                    layer.effect: Glow {
                                        color: Qt.rgba(root.getCardColor(modelData.type).r, root.getCardColor(modelData.type).g, root.getCardColor(modelData.type).b, 0.3)
                                        radius: 15; samples: 15
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: openEdit(modelData)
                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    // Content Layout
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 20
                                        spacing: 8
                                        
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: modelData.title
                                                font.pixelSize: 18
                                                font.bold: true
                                                color: textColor
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Switch {
                                                id: control
                                                checked: modelData.enabled
                                                onCheckedChanged: {
                                                    if (checked !== modelData.enabled) {
                                                        var d = modelData
                                                        d.enabled = checked
                                                        scheduleManager.updateSchedule(modelData.id, d)
                                                    }
                                                }
                                                
                                                indicator: Rectangle {
                                                    implicitWidth: 40
                                                    implicitHeight: 20
                                                    x: control.leftPadding
                                                    y: parent.height / 2 - height / 2
                                                    radius: 10
                                                    color: control.checked ? "#00d2ff" : "#333333"
                                                    border.color: control.checked ? "#00d2ff" : "#666666"
                                                    
                                                    Rectangle {
                                                        x: control.checked ? parent.width - width - 2 : 2
                                                        y: 2
                                                        width: 16
                                                        height: 16
                                                        radius: 8
                                                        color: "#ffffff"
                                                        Behavior on x {
                                                            NumberAnimation { duration: 150 }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        RowLayout {
                                            spacing: 8
                                            ScheduleIcon { type: modelData.type; size: 20; color: root.getCardColor(modelData.type) }
                                            Text {
                                                text: Qt.formatTime(modelData.time, "HH:mm")
                                                font.pixelSize: 24
                                                font.bold: true
                                                color: root.getCardColor(modelData.type)
                                            }
                                        }
                                        
                                        Text {
                                            text: getRepeatText(modelData)
                                            color: secondaryTextColor
                                            font.pixelSize: 14
                                        }
                                        
                                        // Time Perception Display (Red Box Style)
                                        Rectangle {
                                            visible: modelData.timePerceptionText !== "" && modelData.timePerceptionText !== undefined
                                            Layout.fillWidth: true
                                            height: layoutContent.implicitHeight + 12 // Dynamic height
                                            radius: 6
                                            color: Qt.rgba(dangerColor.r, dangerColor.g, dangerColor.b, 0.15)
                                            border.color: Qt.rgba(dangerColor.r, dangerColor.g, dangerColor.b, 0.3)
                                            
                                            RowLayout {
                                                id: layoutContent
                                                anchors.centerIn: parent
                                                width: parent.width - 8
                                                spacing: 6
                                                
                                                Text {
                                                    text: "⏳"
                                                    font.pixelSize: 12
                                                    Layout.alignment: Qt.AlignTop // Align top for multiline
                                                    Layout.topMargin: 3
                                                }
                                                Text {
                                                    text: modelData.timePerceptionText || ""
                                                    color: "#ff3b30" // Red text
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.WordWrap // Enable wrapping
                                                    lineHeight: 1.2 // Nice spacing
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 2. Right Side: Create/Edit Panel (Revealed on Expansion)
            Rectangle {
                id: createPanel
                width: panelWidth
                height: parent.height
                clip: true
                
                // Visibility/Animation Logic
                // It is always "there" in the layout, but the Window width clips it when closed.
                // We add opacity animation for a smoother appearance.
                opacity: isCreatePanelOpen ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                // Panel Background - Consistent with Theme
                color: Qt.rgba(20/255, 30/255, 48/255, 0.5)
                
                // Left Border (Separation from Main View)
                Rectangle {
                    width: 1; height: parent.height
                    color: Qt.rgba(255, 255, 255, 0.1)
                    anchors.left: parent.left
                }

                // Inner Gradient for Depth
                Rectangle {
                    anchors.fill: parent
                    opacity: 0.05
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" } // Inverted gradient
                        GradientStop { position: 1.0; color: "#ffffff" }
                        orientation: Gradient.Horizontal
                    }
                }

                // Form Content
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 24
                    visible: opacity > 0.1 // Optimization

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: currentId ? "编辑提醒" : "创建提醒"
                            font.pixelSize: 24
                            font.bold: true
                            color: textColor
                        }
                        Item { Layout.fillWidth: true }
                        // Close Icon
                        Text {
                            text: "×"
                            font.pixelSize: 28
                            color: secondaryTextColor
                            
                            // Levitation Effect on Hover
                            transform: Translate {
                                y: drawerCloseBtnMouse.containsMouse ? -2 : 0
                                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                id: drawerCloseBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: closeDrawer()
                            }
                        }
                    }
                    
                    // Scrollable Content
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        
                        ColumnLayout {
                            width: parent.width
                            spacing: 24

                            // 1. Title
                            ModernTextField {
                        id: titleField
                        placeholderText: "做什么？(例如：喝水、开会)"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        font.pixelSize: 16
                        background: Rectangle {
                            color: Qt.rgba(0,0,0,0.2)
                            radius: 12
                            border.color: titleField.activeFocus ? primaryColor : "transparent"
                        }
                        onAccepted: saveSchedule()
                    }

                    // 2. Type Chips
                    ColumnLayout {
                        spacing: 12
                        Label { text: "类型"; color: secondaryTextColor; font.pixelSize: 14 }
                        RowLayout {
                            spacing: 12
                            TypeButton { text: "工作"; type: 0; color: primaryColor; selected: typeField.currentType === 0; onClicked: typeField.currentType = 0 }
                            TypeButton { text: "生活"; type: 1; color: accentColor; selected: typeField.currentType === 1; onClicked: typeField.currentType = 1 }
                            TypeButton { text: "纪念"; type: 2; color: dangerColor; selected: typeField.currentType === 2; onClicked: typeField.currentType = 2 }
                            TypeButton { text: "健康"; type: 3; color: healthColor; selected: typeField.currentType === 3; onClicked: typeField.currentType = 3 }
                            Item { id: typeField; property int currentType: 0 }
                        }
                    }

                    // 3. Time
                    RowLayout {
                        spacing: 12
                        Label { text: "时间"; color: secondaryTextColor; font.pixelSize: 14 }
                        RowLayout {
                            spacing: 10
                            // Hour
                            Rectangle {
                                width: 80; height: 60; radius: 12; color: Qt.rgba(0,0,0,0.2)
                                border.color: hourInput.activeFocus ? primaryColor : "transparent"
                                border.width: hourInput.activeFocus ? 1 : 0
                                layer.enabled: hourInput.activeFocus
                                layer.effect: Glow { color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.5); radius: 10; samples: 16 }
                                TimeInput { id: hourInput; max: 23; onNext: minuteInput.forceActiveFocus(); anchors.centerIn: parent; font.pixelSize: 32 }
                            }
                            Text { text: ":"; color: secondaryTextColor; font.pixelSize: 32; font.bold: true }
                            // Minute
                            Rectangle {
                                width: 80; height: 60; radius: 12; color: Qt.rgba(0,0,0,0.2)
                                border.color: minuteInput.activeFocus ? primaryColor : "transparent"
                                border.width: minuteInput.activeFocus ? 1 : 0
                                layer.enabled: minuteInput.activeFocus
                                layer.effect: Glow { color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.5); radius: 10; samples: 16 }
                                TimeInput { id: minuteInput; max: 59; onNext: minuteInput.focus = false; anchors.centerIn: parent; font.pixelSize: 32 }
                            }
                        }
                    }

                    // 4. Repeat
                    ColumnLayout {
                        spacing: 12
                        Layout.fillWidth: true
                        // Layout.fillHeight: true // Removed for ScrollView
                        Label { text: "重复规则"; color: secondaryTextColor; font.pixelSize: 14 }
                        
                        // Custom Tabs
                        RowLayout {
                            spacing: 8
                            Repeater {
                                model: ["单次", "每天", "每周", "每月", "每年", "自定义"]
                                Rectangle {
                                    width: 50; height: 32; radius: 8
                                    color: freqLogic.currentTab === index ? primaryColor : "transparent"
                                    border.color: freqLogic.currentTab === index ? primaryColor : borderColor
                                    Text { 
                                        text: modelData
                                        anchors.centerIn: parent
                                        color: freqLogic.currentTab === index ? "#141E30" : secondaryTextColor 
                                        font.bold: freqLogic.currentTab === index
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: freqLogic.currentTab = index
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                        Item { id: freqLogic; property int currentTab: 1 }

                        // Content per Tab (Same Logic, Better UI)
                        // Once (Tab 0)
                        RowLayout {
                            visible: freqLogic.currentTab === 0
                            Layout.topMargin: 4
                            Label { text: "日期"; color: secondaryTextColor }
                            DatePickerInput {
                                id: onceDateInput
                                implicitWidth: 140
                                placeholderText: "选择日期"
                            }
                        }

                        // Weekly
                        ColumnLayout {
                            visible: freqLogic.currentTab === 2
                            spacing: 10
                            RowLayout {
                                spacing: 8
                                Repeater {
                                    model: ["一", "二", "三", "四", "五", "六", "日"]
                                    Rectangle {
                                        width: 36; height: 36; radius: 18
                                        color: weeklyModel.days[index] ? primaryColor : "transparent"
                                        border.color: weeklyModel.days[index] ? primaryColor : Qt.rgba(255, 255, 255, 0.2)
                                        border.width: 1
                                        
                                        // Glow effect when selected
                                        layer.enabled: weeklyModel.days[index]
                                        layer.effect: Glow {
                                            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.5)
                                            radius: 8
                                            samples: 16
                                        }

                                        Text { 
                                            text: modelData
                                            anchors.centerIn: parent
                                            color: weeklyModel.days[index] ? "#141E30" : "#d0d0d0"
                                            font.bold: weeklyModel.days[index]
                                        }
                                        MouseArea {
                                            anchors.fill: parent; onClicked: weeklyModel.toggle(index)
                                            cursorShape: Qt.PointingHandCursor
                                        }
                                    }
                                }
                            }
                            
                            // Quick Select
                            RowLayout {
                                spacing: 10
                                Layout.topMargin: 4
                                Repeater {
                                    model: [
                                        {label: "工作日", days: [0,1,2,3,4]}, 
                                        {label: "周末", days: [5,6]},
                                        {label: "每天", days: [0,1,2,3,4,5,6]}
                                    ]
                                    Rectangle {
                                        width: 60; height: 24; radius: 12
                                        color: "transparent"
                                        border.color: mouseArea.containsMouse ? primaryColor : Qt.rgba(255,255,255,0.2)
                                        border.width: 1
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: mouseArea.containsMouse ? primaryColor : "#808895"
                                            font.pixelSize: 12
                                        }
                                        
                                        MouseArea {
                                            id: mouseArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: weeklyModel.set(modelData.days)
                                        }
                                    }
                                }
                            }

                            Item {
                                id: weeklyModel
                                property var days: [false,false,false,false,false,false,false]
                                function toggle(i) { var d = days.slice(); d[i] = !d[i]; days = d; }
                                function set(arr) { var d = [false,false,false,false,false,false,false]; for(var i=0;i<arr.length;i++) d[arr[i]]=true; days=d; }
                            }
                        }
                        
                        // Monthly
                        RowLayout {
                            visible: freqLogic.currentTab === 3
                            spacing: 10
                            CustomCheckBox {
                                id: lastDayCheck
                                text: "最后一天"
                                checked: false
                                checkedColor: primaryColor
                            }
                            ModernTextField {
                                id: dayOfMonthInput
                                visible: !lastDayCheck.checked
                                placeholderText: "几号 (1-31)"
                                implicitWidth: 100
                                validator: IntValidator { bottom: 1; top: 31 }
                                enableWheel: true
                            }
                        }

                        // Yearly
                        ColumnLayout {
                            visible: freqLogic.currentTab === 4
                            spacing: 10
                            RowLayout {
                                CustomCheckBox {
                                    id: lunarCheck
                                    text: "农历"
                                    checked: false
                                    checkedColor: primaryColor
                                }
                                ModernTextField {
                                    id: monthInput
                                    placeholderText: "月"
                                    implicitWidth: 60
                                    validator: IntValidator { bottom: 1; top: 12 }
                                    enableWheel: true
                                }
                                Text { text: "-"; color: secondaryTextColor }
                                ModernTextField {
                                    id: dayInput
                                    placeholderText: "日"
                                    implicitWidth: 60
                                    validator: IntValidator { bottom: 1; top: 31 }
                                    enableWheel: true
                                }
                            }
                            RowLayout {
                                CustomCheckBox {
                                    id: advanceCheck
                                    text: "提前提醒"
                                    checked: false
                                    checkedColor: primaryColor
                                }
                                ModernTextField {
                                    id: advanceDaysInput
                                    visible: advanceCheck.checked
                                    placeholderText: "天数"
                                    implicitWidth: 60
                                    text: "7"
                                    validator: IntValidator { bottom: 1; top: 365 }
                                    enableWheel: true
                                }
                                Text { text: "天"; color: secondaryTextColor; visible: advanceCheck.checked }
                            }
                        }

                        // Custom
                        ColumnLayout {
                            visible: freqLogic.currentTab === 5
                            spacing: 10
                            RowLayout {
                                Text { text: "每"; color: secondaryTextColor }
                                ModernTextField {
                                    id: intervalInput
                                    text: "2"
                                    implicitWidth: 40
                                    validator: IntValidator { bottom: 1; top: 99 }
                                    enableWheel: true
                                }
                                CustomComboBox {
                                    id: intervalUnit
                                    model: ["周", "天", "小时", "分钟"]
                                    currentIndex: 0
                                    implicitWidth: 80
                                }
                            }
                            RowLayout {
                                Label { text: "从"; color: secondaryTextColor }
                                DatePickerInput {
                                    id: startDateInput
                                    implicitWidth: 120
                                }
                            }
                        }
                    }

                    // 5. Time Perception (Advanced)
                    ColumnLayout {
                        spacing: 12
                        Layout.fillWidth: true
                        
                        // Toggle Section
                        RowLayout {
                            Label { text: "时间感知"; color: secondaryTextColor; font.pixelSize: 14 }
                            Item { Layout.fillWidth: true }
                            CustomCheckBox {
                                id: perceptionCheck
                                text: "启用"
                                checked: false
                                checkedColor: accentColor
                            }
                        }
                        
                        ColumnLayout {
                            visible: perceptionCheck.checked
                            spacing: 10
                            Layout.fillWidth: true
                            
                            // Target Date & Calendar Type
                            RowLayout {
                                spacing: 10
                                CustomComboBox {
                                    id: perceptionCalendarType
                                    model: ["公历", "农历"]
                                    currentIndex: 0
                                    implicitWidth: 80
                                }
                                DatePickerInput {
                                    id: perceptionTargetDate
                                    implicitWidth: 140
                                    placeholderText: "目标/起始日期"
                                }
                            }
                            
                            // Display Options
                            RowLayout {
                                spacing: 15
                                CustomCheckBox {
                                    id: showTimeSinceCheck
                                    text: "显示已过去" // For Birthday/Anniversary
                                    checkedColor: accentColor
                                }
                                CustomCheckBox {
                                    id: showCountdownCheck
                                    text: "显示倒计时" // For Exam
                                    checkedColor: accentColor
                                }
                                CustomCheckBox {
                                    id: dailyBroadcastCheck
                                    text: "每日播报"
                                    visible: showCountdownCheck.checked
                                    checkedColor: accentColor
                                }
                            }
                            
                            // Auto Switch
                            RowLayout {
                                visible: showCountdownCheck.checked
                                CustomCheckBox {
                                    id: autoSwitchCheck
                                    text: "到期后自动切换为“已过去”" // For Exam -> Post-Exam
                                    checked: true
                                    checkedColor: accentColor
                                }
                            }
                        }
                    }

                            // Prepared Check
                            RowLayout {
                                visible: currentId !== "" && typeField.currentType === 2 && freqLogic.currentTab === 4
                                CustomCheckBox {
                                    id: preparedCheck
                                    text: "今年礼物已准备 (不再提醒)"
                                    checked: false
                                    checkedColor: healthColor
                                }
                            }
                        }
                    }

                    // Footer Actions
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        
                        Button {
                            text: "删除"
                            visible: currentId !== ""
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 44
                            background: Rectangle {
                                color: "transparent"
                                border.color: dangerColor
                                radius: 12
                            }
                            contentItem: Text { text: parent.text; color: dangerColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: {
                                deleteConfirmDialog.open()
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
                        }
                        
                        Item { Layout.fillWidth: true; visible: currentId === "" } // Spacer if no delete button
                        
                        Button {
                            id: cancelBtn
                            text: "取消"
                            visible: currentId === "" || true
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 44
                            
                            // Levitation Effect on Hover
                            transform: Translate {
                                y: cancelBtn.hovered ? -4 : 0
                                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            background: Rectangle { 
                                color: "transparent" 
                                border.color: borderColor 
                                radius: 12 
                                
                                layer.enabled: cancelBtn.hovered
                                layer.effect: Glow {
                                    color: Qt.rgba(255, 255, 255, 0.2)
                                    radius: 10
                                    samples: 10
                                }
                            }
                            contentItem: Text { text: parent.text; color: secondaryTextColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: closeDrawer()
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
                        }

                        Button {
                            id: saveBtn
                            text: "保存设置"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            
                            // Levitation Effect on Hover
                            transform: Translate {
                                y: saveBtn.hovered ? -4 : 0
                                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            background: Rectangle {
                                gradient: Gradient { GradientStop { position: 0.0; color: primaryColor } GradientStop { position: 1.0; color: "#007acc" } }
                                radius: 12
                                layer.enabled: true
                                layer.effect: Glow { 
                                    color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.4)
                                    radius: saveBtn.hovered ? 15 : 10 
                                    samples: 10 
                                    Behavior on radius { NumberAnimation { duration: 200 } }
                                }
                            }
                            contentItem: Text { text: parent.text; color: "#141E30"; font.bold: true; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: saveSchedule()
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
                        }
                    }
                }
            }
        }
        // Toast
        Rectangle {
            id: toast
            width: 200; height: 40; radius: 20
            color: "#E6141E30"; border.color: primaryColor
            anchors.centerIn: parent
            opacity: 0; visible: opacity > 0
            Text { id: toastText; anchors.centerIn: parent; color: "white" }
            function show(msg) { toastText.text = msg; toast.opacity = 1; toastTimer.restart() }
            Timer { id: toastTimer; interval: 1500; onTriggered: toast.opacity = 0 }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // ========================================================================
    // Logic & Helpers
    // ========================================================================
    property point clickPos: "0,0"
    
    function getCardColor(type) {
        if (type === -1) return "#FFFFFF" // All -> White
        if (type === 0) return primaryColor
        if (type === 1) return accentColor
        if (type === 2) return dangerColor
        if (type === 3) return healthColor
        return primaryColor
    }

    function getWeekDay(dateStr) {
        var d = new Date(dateStr)
        if (isNaN(d.getTime())) return ""
        var days = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return days[d.getDay()]
    }

    function getRepeatText(data) {
        var type = (data.repeatType !== undefined) ? data.repeatType : 1
        var rule = data.repeatRule || {}
        var calSuffix = (data.calendarType === 1) ? " (农历)" : " (公历)"
        
        if (type === 0) {
            // Check if we have a target date (for "Once" events)
            if (data.targetDate) {
                 return data.targetDate + calSuffix + " (单次)"
            }
            return "单次"
        }
        if (type === 1) return "每天"
        if (type === 2) {
            var days = rule.days || []
            var str = ""
            var map = ["一", "二", "三", "四", "五", "六", "日"]
            for(var i=0; i<days.length; i++) {
                if (str !== "") str += " "
                str += "周" + map[days[i]-1]
            }
            return str
        }
        if (type === 3) {
            if (rule.day === -1) return "每月最后一天"
            return "每月 " + rule.day + " 日"
        }
        if (type === 4) {
            var str = "每年 " + rule.month + "月" + rule.day + "日" + calSuffix
            if (data.advanceDays > 0) str += " (提前" + data.advanceDays + "天)"
            return str
        }
        if (type === 5) {
            var unit = rule.unit === "week" ? "周" : "天"
            return "每 " + rule.interval + " " + unit
        }
        return "不重复"
    }

    function openCreate() {
        resetEdit()
        isCreatePanelOpen = true
    }

    function openEdit(data) {
        resetEdit() // Clear previous state
        currentId = data.id
        editingData = data // Store full data object
        titleField.text = data.title
        typeField.currentType = data.type
        
        var t = Qt.formatTime(data.time, "HH:mm").split(":")
        hourInput.text = t[0]
        minuteInput.text = t[1]
        
        // Load Frequency
        freqLogic.currentTab = (data.repeatType !== undefined) ? data.repeatType : 1
        var rule = data.repeatRule || {}
        
        if (data.repeatType === 0) { // Once
            if (data.targetDate) {
                 onceDateInput.text = data.targetDate
            } else {
                 onceDateInput.text = Qt.formatDate(new Date(), "yyyy-MM-dd")
            }
        } else if (data.repeatType === 2) { // Weekly
            var days = rule.days || []
            weeklyModel.set(days.map(function(d){return d-1}))
        } else if (data.repeatType === 3) { // Monthly
            lastDayCheck.checked = (rule.day === -1)
            if (rule.day !== -1) dayOfMonthInput.text = rule.day
        } else if (data.repeatType === 4) { // Yearly
            // Check if using Lunar
            // Assuming data.calendarType is set. If not, default to 0 (Gregorian)
            if (data.calendarType === 1) {
                lunarCheck.checked = true
            } else {
                lunarCheck.checked = false
            }

            monthInput.text = rule.month
            dayInput.text = rule.day
            advanceCheck.checked = (data.advanceDays > 0)
            if (data.advanceDays > 0) advanceDaysInput.text = data.advanceDays
            preparedCheck.checked = data.isPrepared || false
        } else if (data.repeatType === 5) { // Custom
            intervalInput.text = rule.interval
            var u = rule.unit
            if (u === "week") intervalUnit.currentIndex = 0
            else if (u === "day") intervalUnit.currentIndex = 1
            else if (u === "hour") intervalUnit.currentIndex = 2
            else if (u === "minute") intervalUnit.currentIndex = 3
            else intervalUnit.currentIndex = 1 // Default to day
            
            // For hour/minute, startDate is still used as anchor date
            if (rule.startDate) {
                // startDate is QDate string in JSON, but rule.startDate might be QDate object if coming from C++ directly?
                // Actually openEdit(data) comes from QVariantMap
                // If it's a string
                startDateInput.text = (typeof rule.startDate === 'string' ? rule.startDate : Qt.formatDate(rule.startDate, "yyyy-MM-dd"))
            }
        }

        // Time Perception
        if (data.showTimeSince || data.showCountdown) {
            perceptionCheck.checked = true
            perceptionCalendarType.currentIndex = (data.calendarType === 1 ? 1 : 0)
            if (data.targetDate) {
                 perceptionTargetDate.text = data.targetDate
            }
            showTimeSinceCheck.checked = data.showTimeSince
            showCountdownCheck.checked = data.showCountdown
            dailyBroadcastCheck.checked = data.dailyBroadcast
            autoSwitchCheck.checked = data.autoSwitch
        } else {
            perceptionCheck.checked = false
        }
        
        isCreatePanelOpen = true
    }
    
    function resetEdit() {
        currentId = ""
        editingData = null
        titleField.text = ""
        typeField.currentType = 0
        hourInput.text = "09"
        minuteInput.text = "00"
        freqLogic.currentTab = 1
        weeklyModel.days = [false,false,false,false,false,false,false]
        onceDateInput.text = Qt.formatDate(new Date(), "yyyy-MM-dd")
        lastDayCheck.checked = false
        dayOfMonthInput.text = ""
        lunarCheck.checked = false
        monthInput.text = ""
        dayInput.text = ""
        advanceCheck.checked = false
        advanceDaysInput.text = "7"
        intervalInput.text = "2"
        intervalUnit.currentIndex = 0
        startDateInput.text = Qt.formatDate(new Date(), "yyyy-MM-dd")
        preparedCheck.checked = false
        
        // Reset Time Perception
        perceptionCheck.checked = false
        perceptionCalendarType.currentIndex = 0
        perceptionTargetDate.text = ""
        showTimeSinceCheck.checked = false
        showCountdownCheck.checked = false
        dailyBroadcastCheck.checked = false
        autoSwitchCheck.checked = true
    }

    function closeDrawer() {
        isCreatePanelOpen = false
    }

    function saveSchedule() {
        if (titleField.text === "") {
            toast.show("请输入内容")
            return
        }
        
        var h = parseInt(hourInput.text)
        var m = parseInt(minuteInput.text)
        if (isNaN(h) || isNaN(m) || h<0 || h>23 || m<0 || m>59) {
            toast.show("时间格式错误")
            return
        }
        
        var now = new Date()
        
        if (freqLogic.currentTab === 0) { // Once
            var dateStr = onceDateInput.text
            if (dateStr === "") { toast.show("请选择日期"); return }
            var d = new Date(dateStr)
            if (isNaN(d.getTime())) { toast.show("日期格式错误"); return }
            now = d
        }
        
        now.setHours(h)
        now.setMinutes(m)
        now.setSeconds(0)
        
        // Determine Calendar Type (Global for item, used by Repeat and Perception)
        // Priority: If Yearly tab is selected, use lunarCheck. 
        // If Perception is enabled, use perceptionCalendarType.
        // Ideally they should be consistent or we store them separately?
        // ScheduleItem has one `calendarType`.
        // If Repeat is Yearly, we use `lunarCheck`.
        // If Repeat is Once (Countdown), we use `perceptionCalendarType`.
        
        var calType = 0
        if (freqLogic.currentTab === 4) { // Yearly
             calType = lunarCheck.checked ? 1 : 0
        } else if (perceptionCheck.checked) {
             calType = perceptionCalendarType.currentIndex === 1 ? 1 : 0
        }
        
        var repeatRule = {}
        if (freqLogic.currentTab === 2) { // Weekly
            var days = []
            for(var i=0; i<7; i++) {
                if (weeklyModel.days[i]) days.push(i+1)
            }
            if (days.length === 0) { toast.show("请选择星期"); return }
            repeatRule = { days: days }
        } else if (freqLogic.currentTab === 3) { // Monthly
            if (lastDayCheck.checked) {
                repeatRule = { day: -1 }
            } else {
                var d = parseInt(dayOfMonthInput.text)
                if (isNaN(d) || d < 1 || d > 31) { toast.show("日期错误"); return }
                repeatRule = { day: d }
            }
        } else if (freqLogic.currentTab === 4) { // Yearly
            var mm = parseInt(monthInput.text)
            var dd = parseInt(dayInput.text)
            if (isNaN(mm) || isNaN(dd)) { toast.show("日期错误"); return }
            repeatRule = { month: mm, day: dd }
        } else if (freqLogic.currentTab === 5) { // Custom
            var interval = parseInt(intervalInput.text)
            if (isNaN(interval)) { toast.show("间隔错误"); return }
            
            var units = ["week", "day", "hour", "minute"]
            var selectedUnit = units[intervalUnit.currentIndex]
            
            repeatRule = {
                interval: interval,
                unit: selectedUnit,
                startDate: startDateInput.text
            }
        }

        var data = {
            id: currentId, // Preserve ID
            title: titleField.text,
            type: typeField.currentType,
            time: now,
            enabled: editingData ? editingData.enabled : true, // Preserve enabled state
            repeatType: freqLogic.currentTab,
            repeatRule: repeatRule,
            advanceDays: (advanceCheck.checked ? parseInt(advanceDaysInput.text) : 0),
            isPrepared: preparedCheck.checked,
            lastTriggered: editingData ? editingData.lastTriggered : undefined, // Preserve lastTriggered
            
            // Time Perception
            calendarType: calType,
            targetDate: (perceptionCheck.checked && perceptionTargetDate.text !== "" ? perceptionTargetDate.text : (freqLogic.currentTab === 0 ? Qt.formatDate(now, "yyyy-MM-dd") : "")),
            showTimeSince: (perceptionCheck.checked ? showTimeSinceCheck.checked : (freqLogic.currentTab === 0 && now < new Date())),
            showCountdown: (perceptionCheck.checked ? showCountdownCheck.checked : (freqLogic.currentTab === 0 && now >= new Date())),
            dailyBroadcast: (perceptionCheck.checked && showCountdownCheck.checked && dailyBroadcastCheck.checked),
            autoSwitch: (perceptionCheck.checked ? autoSwitchCheck.checked : true)
        }
        
        if (currentId) {
            scheduleManager.updateSchedule(currentId, data)
            toast.show("已更新")
        } else {
            scheduleManager.addSchedule(data)
            toast.show("已创建")
        }
        closeDrawer()
    }

    // Delete Confirmation Dialog
    Rectangle {
        id: deleteConfirmDialog
        anchors.fill: parent
        color: "#AA000000" // Semi-transparent black
        visible: false
        z: 999 // Ensure it's on top
        
        property string pendingId: ""

        function open() {
            pendingId = currentId
            visible = true
        }

        function close() {
            visible = false
            pendingId = ""
        }

        MouseArea { anchors.fill: parent; onClicked: deleteConfirmDialog.close() } // Click outside to close

        Rectangle {
            width: 320; height: 180
            anchors.centerIn: parent
            color: "#141E30"
            border.color: borderColor
            border.width: 1
            radius: 12

            MouseArea { anchors.fill: parent } // Block click through

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Text {
                    text: "确认删除"
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "确定要删除这个提醒吗？\n此操作无法撤销。"
                    color: secondaryTextColor
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Item { Layout.fillHeight: true } // Spacer

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Button {
                        text: "取消"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        background: Rectangle {
                            color: "transparent"
                            border.color: borderColor
                            radius: 8
                        }
                        contentItem: Text { text: parent.text; color: secondaryTextColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: deleteConfirmDialog.close()
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
                    }

                    Button {
                        text: "确认删除"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        background: Rectangle {
                            color: dangerColor
                            radius: 8
                        }
                        contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: {
                            scheduleManager.removeSchedule(deleteConfirmDialog.pendingId)
                            deleteConfirmDialog.close()
                            closeDrawer() // Close the edit drawer too
                            toast.show("已删除")
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
                    }
                }
            }
        }
    }
}
