import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Window {
    id: dashboardWindow
    width: 1200
    height: 720
    visible: true
    title: "活动轨迹与效率分析"
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window
    onVisibleChanged: {
        if (visible) {
            requestActivate()
            // 每次显示时刷新数据，确保显示最新统计
            refreshData() 
        }
    }

    property date currentDate: new Date()
    property color themeColor: "#00d2ff" // Default theme color
    property var highlightFilter: null // { type: int, minDuration: int, startTime: qint64 }
    onHighlightFilterChanged: timelineCanvas.requestPaint()
    
    // Legacy property for compatibility (removed usage but kept for safety if needed temporarily)
    property int highlightedType: -1

    // Colors
    readonly property color colorFocus: "#00d2ff"   // Tech Blue
    readonly property color colorRest: "#00ff88"    // Spring Green
    readonly property color colorNap: "#d000ff"     // Neon Purple
    readonly property color colorPause: "#ffbf00"   // Amber Gold
    readonly property color colorOffline: "#555555" // Dim Grey
    readonly property color colorBackground: "#1B2A4E" // Deep Blue Background

    // 拖拽窗口逻辑
    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: 10 // Leave edge for resizing if needed (not implemented here)
        property point clickPos: "0,0"
        onPressed: {
            clickPos = Qt.point(mouse.x, mouse.y)
        }
        onPositionChanged: {
            var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
            dashboardWindow.x += delta.x
            dashboardWindow.y += delta.y
        }
        z: -1 // Behind content
    }

    // 主背景容器
    Rectangle {
        id: mainBackground
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(0.10, 0.16, 0.30, 0.95) // #1B2A4E with 95% opacity
        border.color: Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.3)
        border.width: 1
        
        // Force rendering into a texture to avoid partial repaint artifacts
        layer.enabled: true
        layer.smooth: true
        
        // Entry Animation: Fade in to prevent ghosting artifacts
        opacity: 0
        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 300
            easing.type: Easing.OutCubic
            running: true
        }

        // 玻璃拟态光效 (顶部高光)
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.2)
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // 内容区域
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // 1. 标题栏
            RowLayout {
                Layout.fillWidth: true
                spacing: 15

                Text {
                    text: "📊 活动轨迹与效率分析"
                    font.pixelSize: 22
                    font.bold: true
                    color: "white"
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true } // Spacer

                // 日期导航
                Button {
                    text: "◀"
                    flat: true
                    contentItem: Text {
                        text: parent.text
                        color: parent.hovered ? themeColor : "#AAAAAA"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: "transparent" }
                    onClicked: {
                        var d = new Date(currentDate);
                        d.setDate(d.getDate() - 1);
                        currentDate = d;
                        refreshData();
                    }
                }

                Text {
                    text: currentDate.toLocaleDateString(Qt.locale(), "yyyy年M月d日 dddd")
                    font.pixelSize: 18
                    font.bold: true
                    color: "white"
                    Layout.alignment: Qt.AlignVCenter
                }

                Button {
                    text: "▶"
                    flat: true
                    contentItem: Text {
                        text: parent.text
                        color: parent.hovered ? themeColor : "#AAAAAA"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: "transparent" }
                    onClicked: {
                        var d = new Date(currentDate);
                        d.setDate(d.getDate() + 1);
                        currentDate = d;
                        refreshData();
                    }
                }

                Item { width: 20 }

                // 关闭按钮
                Rectangle {
                    width: 32
                    height: 32
                    color: "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeMouseArea.containsMouse ? "#FF5555" : "#AAAAAA"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dashboardWindow.close()
                    }
                }
            }

            // 分割线
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.1)
            }

            // 2. 核心统计卡片
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 15
                columnSpacing: 15

                Repeater {
                    model: statsModel
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 110
                        color: Qt.rgba(1, 1, 1, 0.05)
                        radius: 12
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        // Hover effect
                        scale: 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                parent.color = Qt.rgba(1, 1, 1, 0.1)
                                parent.scale = 1.03
                                
                                var filter = {};
                                // Use flat properties to avoid ListModel nested object issues
                                if (model.filterType !== undefined) filter.type = model.filterType;
                                if (model.filterMinDuration !== undefined) filter.minDuration = model.filterMinDuration;
                                if (model.filterStartTime !== undefined) filter.startTime = model.filterStartTime;
                                
                                if (Object.keys(filter).length > 0) {
                                    dashboardWindow.highlightFilter = filter;
                                } else if (model.type !== undefined) {
                                    dashboardWindow.highlightFilter = { type: model.type }
                                }
                            }
                            onExited: {
                                parent.color = Qt.rgba(1, 1, 1, 0.05)
                                parent.scale = 1.0
                                dashboardWindow.highlightFilter = null
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 8

                            RowLayout {
                                spacing: 10
                                Text {
                                    text: model.icon
                                    font.pixelSize: 24
                                }
                                Text {
                                    text: model.title
                                    font.pixelSize: 14
                                    color: "#BBBBBB"
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                text: model.value
                                font.pixelSize: 24
                                font.bold: true
                                color: "white" // model.color
                                style: Text.Outline
                                styleColor: Qt.rgba(model.color.r, model.color.g, model.color.b, 0.3)
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 2
                                color: model.color
                                opacity: 0.8
                            }
                        }
                    }
                }
            }

            // 3. 时间轴可视化区域
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.2) // Darker inner background
                radius: 12
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10

                    Text {
                        text: "全天活动时间分布 (00:00 - 24:00)"
                        font.pixelSize: 14
                        color: "#DDDDDD"
                    }

                    // Canvas 绘图区域
                    Canvas {
                        id: timelineCanvas
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        property var activityData: []
                        
                        // Zoom State
                        property double viewStartHour: 0.0
                        property double viewEndHour: 24.0

                        onPaint: {
                            var ctx = getContext("2d");
                            var w = width;
                            var h = height;

                            ctx.clearRect(0, 0, w, h);

                            // Zoom calculations
                            var durationHours = viewEndHour - viewStartHour;
                            var pixelsPerHour = w / durationHours;

                            // 1. 绘制网格和时间刻度
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.1);
                            ctx.lineWidth = 1;
                            ctx.font = "12px sans-serif";
                            ctx.fillStyle = "#888888";
                            ctx.textAlign = "center";
                            
                            var gridBottom = h - 40;
                            var startGrid = Math.floor(viewStartHour);
                            var endGrid = Math.ceil(viewEndHour);

                            for (var i = startGrid; i <= endGrid; i++) {
                                if (i < 0 || i > 24) continue;
                                var x = (i - viewStartHour) * pixelsPerHour;
                                
                                // Grid line
                                ctx.beginPath();
                                ctx.moveTo(x, 10);
                                ctx.lineTo(x, gridBottom); 
                                ctx.stroke();

                                // Label (Smart Interval)
                                var interval = (durationHours <= 6) ? 1 : (durationHours <= 12 ? 2 : 4);
                                if (i % interval === 0) { 
                                    ctx.fillText(i + ":00", x, h - 15);
                                }
                            }

                            // 2. 绘制活动条
                            var barY = (gridBottom - 10) / 2 - 20; 
                            var barHeight = 60;
                            var cornerRadius = 4;

                            // Background track
                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.05);
                            roundedRect(ctx, 0, barY, w, barHeight, cornerRadius);
                            ctx.fill();

                            if (!activityData) return;

                            var midnight = new Date(currentDate);
                            midnight.setHours(0,0,0,0);
                            var midnightTs = midnight.getTime(); 
                            var viewStartSec = viewStartHour * 3600;
                            var viewEndSec = viewEndHour * 3600;
                            var viewDurationSec = durationHours * 3600;

                            for (var j = 0; j < activityData.length; j++) {
                                var act = activityData[j];
                                var actStartSec = (act.startTime - midnightTs) / 1000;
                                var actEndSec = (act.endTime - midnightTs) / 1000;

                                // Visibility check
                                if (actEndSec < viewStartSec || actStartSec > viewEndSec) continue;

                                // Clamp
                                var visibleStart = Math.max(actStartSec, viewStartSec);
                                var visibleEnd = Math.min(actEndSec, viewEndSec);
                                
                                var x = ((visibleStart - viewStartSec) / viewDurationSec) * w;
                                var bw = ((visibleEnd - visibleStart) / viewDurationSec) * w;
                                
                                // Ensure minimum visibility for short durations
                                if (bw < 2) bw = 2;

                                ctx.fillStyle = getColorForType(act.type);
                                
                                // Highlight logic
                            var isHighlighted = true;
                            if (dashboardWindow.highlightFilter) {
                                var f = dashboardWindow.highlightFilter;
                                var typeMatch = (f.type === undefined || f.type === -1) || (act.type === f.type);
                                var minDurationMatch = (f.minDuration === undefined || f.minDuration === -1) || (act.duration > f.minDuration);
                                // Allow small time slop (1000ms) for floating point/conversion diffs
                                var startTimeMatch = (f.startTime === undefined || f.startTime === -1) || (Math.abs(act.startTime - f.startTime) < 1000); 
                                
                                if (!typeMatch || !minDurationMatch || !startTimeMatch) {
                                    isHighlighted = false;
                                }
                            }
                            
                            if (isHighlighted) {
                                ctx.globalAlpha = 1.0;
                                ctx.fillRect(x, barY + 5, bw, barHeight - 10);
                                
                                // Smart Label
                                if (bw > 30) {
                                    ctx.save();
                                    ctx.fillStyle = "white";
                                    ctx.font = "bold 11px sans-serif";
                                    ctx.textAlign = "center";
                                    ctx.textBaseline = "middle";
                                    var durationMins = Math.floor(act.duration / 60);
                                    if (durationMins > 0) {
                                        ctx.fillText(durationMins + "m", x + bw/2, barY + barHeight/2);
                                    }
                                    ctx.restore();
                                }

                                // Detail Bubble for Specific Segment Highlight
                                if (dashboardWindow.highlightFilter && 
                                    dashboardWindow.highlightFilter.startTime !== undefined && 
                                    dashboardWindow.highlightFilter.startTime !== -1) {
                                    
                                    var bubbleW = 160;
                                    var bubbleH = 54;
                                    var bx = x + bw/2 - bubbleW/2;
                                    var by = barY - bubbleH - 12; // Above the bar with spacing
                                    
                                    // Clamp to canvas edges
                                    if (bx < 10) bx = 10;
                                    if (bx + bubbleW > w - 10) bx = w - bubbleW - 10;
                                    
                                    ctx.save();
                                    // Shadow
                                    ctx.shadowColor = "rgba(0,0,0,0.4)";
                                    ctx.shadowBlur = 8;
                                    ctx.shadowOffsetY = 3;
                                    
                                    // Background
                                    ctx.fillStyle = "#F01B2A4E"; // High opacity dark blue
                                    roundedRect(ctx, bx, by, bubbleW, bubbleH, 8);
                                    ctx.fill();
                                    
                                    // Border
                                    ctx.shadowColor = "transparent";
                                    ctx.strokeStyle = getColorForType(act.type);
                                    ctx.lineWidth = 1.5;
                                    ctx.stroke();
                                    
                                    // Content
                                    ctx.fillStyle = "white";
                                    ctx.textAlign = "center";
                                    
                                    // Title: Type + Duration
                                    ctx.font = "bold 13px sans-serif";
                                    var typeName = getStateName(act.type);
                                    var d = act.duration;
                                    var durStr = (d > 3600) ? (Math.floor(d/3600) + "h " + Math.floor((d%3600)/60) + "m") : (Math.floor(d/60) + "m " + (d%60) + "s");
                                    ctx.fillText(typeName + " · " + durStr, bx + bubbleW/2, by + 20);
                                    
                                    // Time Range
                                    ctx.font = "12px sans-serif";
                                    ctx.fillStyle = "#CCCCCC";
                                    var st = new Date(act.startTime);
                                    var et = new Date(act.endTime);
                                    // Manually format time to ensure HH:mm consistency
                                    var timeRange = Qt.formatTime(st, "HH:mm") + " - " + Qt.formatTime(et, "HH:mm");
                                    ctx.fillText(timeRange, bx + bubbleW/2, by + 40);
                                    
                                    // Triangle pointer
                                    ctx.beginPath();
                                    ctx.moveTo(x + bw/2 - 6, by + bubbleH);
                                    ctx.lineTo(x + bw/2 + 6, by + bubbleH);
                                    ctx.lineTo(x + bw/2, by + bubbleH + 6);
                                    ctx.closePath();
                                    ctx.fillStyle = getColorForType(act.type);
                                    ctx.fill();
                                    
                                    ctx.restore();
                                }

                            } else {
                                ctx.globalAlpha = 0.15; // Dim others
                                ctx.fillRect(x, barY + 5, bw, barHeight - 10);
                            }
                            }
                            ctx.globalAlpha = 1.0; // Reset
                        }
                        
                        // Helper for rounded rect (Canvas 2D)
                        function roundedRect(ctx, x, y, width, height, radius) {
                            ctx.beginPath();
                            ctx.moveTo(x + radius, y);
                            ctx.lineTo(x + width - radius, y);
                            ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
                            ctx.lineTo(x + width, y + height - radius);
                            ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
                            ctx.lineTo(x + radius, y + height);
                            ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
                            ctx.lineTo(x, y + radius);
                            ctx.quadraticCurveTo(x, y, x + radius, y);
                            ctx.closePath();
                        }

                        // Hover & Zoom & Drag Handling
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            property real lastDragX: 0

                            onPressed: {
                                lastDragX = mouseX
                            }

                            onWheel: {
                                var angle = wheel.angleDelta.y;
                                if (angle === 0) return;
                                
                                var zoomFactor = 0.1;
                                var duration = timelineCanvas.viewEndHour - timelineCanvas.viewStartHour;
                                var mouseRatio = mouseX / width;
                                var cursorTime = timelineCanvas.viewStartHour + mouseRatio * duration;
                                
                                var newDuration = duration;
                                if (angle > 0) { // Zoom In
                                    newDuration = duration * (1 - zoomFactor);
                                } else { // Zoom Out
                                    newDuration = duration * (1 + zoomFactor);
                                }
                                
                                // Clamp duration
                                if (newDuration < 1) newDuration = 1; // Min 1 hour
                                if (newDuration > 24) newDuration = 24; // Max 24 hours
                                
                                // Adjust start to keep cursor time stable
                                var newStart = cursorTime - mouseRatio * newDuration;
                                
                                // Clamp start/end
                                if (newStart < 0) newStart = 0;
                                if (newStart + newDuration > 24) newStart = 24 - newDuration;
                                
                                timelineCanvas.viewStartHour = newStart;
                                timelineCanvas.viewEndHour = newStart + newDuration;
                                timelineCanvas.requestPaint();
                            }

                            onDoubleClicked: {
                                timelineCanvas.viewStartHour = 0;
                                timelineCanvas.viewEndHour = 24;
                                timelineCanvas.requestPaint();
                            }

                            onPositionChanged: {
                                // Drag Handling
                                if (pressed) {
                                    var dx = mouseX - lastDragX;
                                    lastDragX = mouseX;
                                    
                                    var duration = timelineCanvas.viewEndHour - timelineCanvas.viewStartHour;
                                    var deltaHour = -(dx / width) * duration;
                                    
                                    var newStart = timelineCanvas.viewStartHour + deltaHour;
                                    
                                    // Clamp
                                    if (newStart < 0) newStart = 0;
                                    if (newStart + duration > 24) newStart = 24 - duration;
                                    
                                    timelineCanvas.viewStartHour = newStart;
                                    timelineCanvas.viewEndHour = newStart + duration;
                                    timelineCanvas.requestPaint();
                                    
                                    tooltip.visible = false;
                                    return;
                                }

                                var hoveredAct = null;
                                var data = timelineCanvas.activityData;
                                if (!data) return;

                                var w = width;
                                var viewStartSec = timelineCanvas.viewStartHour * 3600;
                                var viewEndSec = timelineCanvas.viewEndHour * 3600;
                                var viewDurationSec = viewEndSec - viewStartSec;
                                
                                var midnight = new Date(currentDate);
                                midnight.setHours(0,0,0,0);
                                var midnightTs = midnight.getTime();

                                // Calculate cursor time (Used for both Time-based Check and Gap Detection)
                                var cursorRatio = mouseX / w;
                                var cursorTimeSec = viewStartSec + cursorRatio * viewDurationSec;
                                var cursorTs = midnightTs + cursorTimeSec * 1000;

                                // 1. Visual Hit Test (Priority: Matches what user sees)
                                for (var k = 0; k < data.length; k++) {
                                    var act = data[k];
                                    var actStartSec = (act.startTime - midnightTs) / 1000;
                                    var actEndSec = (act.endTime - midnightTs) / 1000;

                                    // Visibility check
                                    if (actEndSec < viewStartSec || actStartSec > viewEndSec) continue;

                                    // Calculate visual geometry
                                    var visibleStart = Math.max(actStartSec, viewStartSec);
                                    var visibleEnd = Math.min(actEndSec, viewEndSec);
                                    
                                    var x = ((visibleStart - viewStartSec) / viewDurationSec) * w;
                                    var bw = ((visibleEnd - visibleStart) / viewDurationSec) * w;
                                    
                                    // Ensure minimum visibility for short durations (matching onPaint)
                                    if (bw < 2) bw = 2;

                                    // Hit detection
                                    if (mouseX >= x && mouseX <= x + bw) {
                                        hoveredAct = act;
                                    }
                                }

                                // 2. Time-based Fallback (If visual missed but we are mathematically inside)
                                // This prevents the "Huge Offline Gap" issue when visual hit test fails marginally
                                if (!hoveredAct) {
                                    for (var k = 0; k < data.length; k++) {
                                        var act = data[k];
                                        if (cursorTs >= act.startTime && cursorTs < act.endTime) {
                                            hoveredAct = act;
                                            // Don't break, keep looking for later (overlapping) activities to match painter's algo
                                        }
                                    }
                                }

                                // 3. Gap Detection (If really nothing found)
                                if (!hoveredAct) {
                                    var maxPrevEnd = midnightTs;
                                    var minNextStart = midnightTs + 24 * 3600 * 1000;
                                    
                                    for (var m = 0; m < data.length; m++) {
                                        var a = data[m];
                                        // Find tightest bounds surrounding cursorTs
                                        // Note: We already know cursorTs is NOT inside 'a' (due to Step 2)
                                        if (a.endTime <= cursorTs) {
                                            if (a.endTime > maxPrevEnd) maxPrevEnd = a.endTime;
                                        } 
                                        if (a.startTime >= cursorTs) {
                                            if (a.startTime < minNextStart) minNextStart = a.startTime;
                                        }
                                    }
                                    
                                    // Valid gap found?
                                    if (cursorTs >= maxPrevEnd && cursorTs <= minNextStart) {
                                         hoveredAct = {
                                             type: -1, // Offline
                                             startTime: maxPrevEnd,
                                             endTime: minNextStart,
                                             duration: (minNextStart - maxPrevEnd) / 1000
                                         };
                                    }
                                }

                                if (hoveredAct) {
                                    var startTimeStr = new Date(hoveredAct.startTime).toLocaleTimeString(Qt.locale(), "HH:mm");
                                    var endTimeStr = new Date(hoveredAct.endTime).toLocaleTimeString(Qt.locale(), "HH:mm");
                                    var durationMins = Math.floor(hoveredAct.duration / 60);
                                    if (durationMins < 1) durationMins = "< 1";

                                    tooltipText.text = getStateName(hoveredAct.type) + "\n" + 
                                                   startTimeStr + " - " + endTimeStr + "\n" +
                                                   "持续: " + durationMins + " 分钟";
                                    
                                    // Tooltip position smarts
                                    var tx = mouseX + 15;
                                    if (tx + tooltip.width > width) tx = mouseX - tooltip.width - 15;
                                    
                                    tooltip.x = tx;
                                    tooltip.y = mouseY + 15;
                                    tooltip.visible = true;
                                    tooltip.border.color = getColorForType(hoveredAct.type);
                                } else {
                                    tooltip.visible = false;
                                }
                            }
                            onExited: tooltip.visible = false
                        }

                        // Tooltip Element
                        Rectangle {
                            id: tooltip
                            visible: false
                            width: tooltipText.contentWidth + 24
                            height: tooltipText.contentHeight + 20
                            color: "#E61B2A4E" // High opacity dark blue
                            radius: 8
                            border.width: 1
                            border.color: "white"
                            
                            // Shadow
                            layer.enabled: true
                            layer.effect: DropShadow {
                                transparentBorder: true
                                color: "#80000000"
                                radius: 8
                            }

                            Text {
                                id: tooltipText
                                anchors.centerIn: parent
                                color: "white"
                                font.pixelSize: 13
                                lineHeight: 1.4
                                text: ""
                            }
                        }
                    }
                    
                    // Legend (图例)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20
                        
                        Repeater {
                            model: [
                                { name: "专注工作", color: colorFocus },
                                { name: "运动休息", color: colorRest },
                                { name: "午休睡眠", color: colorNap },
                                { name: "暂停状态", color: colorPause },
                                { name: "离线/未知", color: colorOffline }
                            ]
                            delegate: Row {
                                spacing: 6
                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: modelData.color
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.name
                                    color: "#AAAAAA"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ========================================================================
    // Logic Functions
    // ========================================================================

    function getColorForType(type) {
        switch(type) {
            case 0: return colorFocus;
            case 1: return colorRest;
            case 2: return colorNap;
            case 3: return colorPause;
            default: return colorOffline;
        }
    }

    function getStateName(type) {
        switch(type) {
            case 0: return "专注工作";
            case 1: return "运动休息";
            case 2: return "午休睡眠";
            case 3: return "暂停状态";
            default: return "离线/未知";
        }
    }

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a).toString();
    }

    function refreshData() {
        var activities = activityLogger.getDailyActivities(currentDate);
        var stats = activityLogger.getDailyStats(currentDate);

        timelineCanvas.activityData = activities;
        timelineCanvas.requestPaint();

        statsModel.clear();
        
        // Row 1
        statsModel.append({
            "title": "专注总时长",
            "value": formatDuration(stats.totalFocusSeconds),
            "icon": "⏱️",
            "color": colorFocus.toString(),
            "shadowColor": withAlpha(colorFocus, 0.3),
            "type": 0,
            "filterType": 0,
            "filterMinDuration": -1,
            "filterStartTime": -1
        });
        statsModel.append({
            "title": "运动总时长",
            "value": formatDuration(stats.totalRestSeconds),
            "icon": "🧘",
            "color": colorRest.toString(),
            "shadowColor": withAlpha(colorRest, 0.3),
            "type": 1,
            "filterType": 1,
            "filterMinDuration": -1,
            "filterStartTime": -1
        });
        statsModel.append({
            "title": "午休总时长",
            "value": formatDuration(stats.totalNapSeconds),
            "icon": "🛌",
            "color": colorNap.toString(),
            "shadowColor": withAlpha(colorNap, 0.3),
            "type": 2,
            "filterType": 2,
            "filterMinDuration": -1,
            "filterStartTime": -1
        });
        statsModel.append({
            "title": "总暂停时长",
            "value": formatDuration(stats.totalPauseSeconds),
            "icon": "⏸️",
            "color": colorPause.toString(),
            "shadowColor": withAlpha(colorPause, 0.3),
            "type": 3,
            "filterType": 3,
            "filterMinDuration": -1,
            "filterStartTime": -1
        });

        // Row 2
        statsModel.append({
            "title": "专注段数(>30分钟)",
            "value": stats.focusSessionCount + " 次",
            "icon": "🔢",
            "color": colorFocus.toString(),
            "shadowColor": withAlpha(colorFocus, 0.3),
            "type": 0,
            "filterType": 0,
            "filterMinDuration": 1800,
            "filterStartTime": -1
        });
        statsModel.append({
            "title": "最长连续专注",
            "value": formatDuration(stats.maxFocusSeconds),
            "icon": "🔥",
            "color": colorFocus.toString(),
            "shadowColor": withAlpha(colorFocus, 0.3),
            "type": 0,
            "filterType": 0,
            "filterMinDuration": -1,
            "filterStartTime": stats.maxFocusStart
        });
        statsModel.append({
            "title": "最长连续运动",
            "value": formatDuration(stats.maxRestSeconds),
            "icon": "🏃",
            "color": colorRest.toString(),
            "shadowColor": withAlpha(colorRest, 0.3),
            "type": 1,
            "filterType": 1,
            "filterMinDuration": -1,
            "filterStartTime": stats.maxRestStart
        });
        statsModel.append({
            "title": "最长暂停时间",
            "value": formatDuration(stats.maxPauseSeconds),
            "icon": "⏳",
            "color": colorPause.toString(),
            "shadowColor": withAlpha(colorPause, 0.3),
            "type": 3,
            "filterType": 3,
            "filterMinDuration": -1,
            "filterStartTime": stats.maxPauseStart
        });
    }

    function formatDuration(seconds) {
        if (!seconds || seconds === 0) return "0秒";
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var s = seconds % 60;
        
        if (h > 0) return h + "小时" + m + "分";
        if (m > 0) return m + "分" + s + "秒";
        return s + "秒";
    }

    Component.onCompleted: {
        refreshData();
    }
    
    ListModel {
        id: statsModel
    }
}
