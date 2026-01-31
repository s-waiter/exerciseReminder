import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

// ========================================================================
// NapWindow.qml - 午休助眠模式窗口
// ========================================================================
// 极简全屏黑色窗口，提供无干扰的午休环境。
// 特性：
// 1. 全黑背景 (OLED 省电/护眼)
// 2. 极暗时钟 (防烧屏位移)
// 3. 长按退出 (防误触)
// ========================================================================

Window {
    id: napWin
    // 绑定后端状态：支持淡入淡出效果
    visible: timerEngine.isNapMode || opacity > 0
    opacity: timerEngine.isNapMode ? 1.0 : 0.0
    
    Behavior on opacity {
        NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad }
    }
    
    // 强制全屏 + 置顶 + 无边框
    flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
    color: "#000000" // 纯黑背景
    
    // 自动全屏逻辑
    onVisibleChanged: {
        if (visible) {
            showFullScreen()
            raise()
        } else {
            resetExitState()
        }
    }

    // -------------------------------------------------------------------------
    // 1. 动态时钟 (防烧屏)
    // -------------------------------------------------------------------------
    Item {
        id: clockContainer
        width: 300
        height: 150
        // 初始居中
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        // 时钟文本
        Text {
            id: timeText
            anchors.centerIn: parent
            color: "white"
            opacity: 0.2 // 极低亮度
            font.pixelSize: 80
            font.family: "Segoe UI Light"
            text: Qt.formatTime(new Date(), "HH:mm")
        }
        
        // 日期文本
        Text {
            anchors.top: timeText.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            opacity: 0.15
            font.pixelSize: 24
            font.family: "Segoe UI"
            text: Qt.formatDate(new Date(), "MM-dd dddd")
        }
    }

    // 定时器：每秒更新时间，每5分钟移动位置
    Timer {
        interval: 1000
        running: napWin.visible
        repeat: true
        onTriggered: {
            var now = new Date()
            timeText.text = Qt.formatTime(now, "HH:mm")
            
            // 每5分钟 (300秒) 随机微调位置，防止 OLED 烧屏
            if (now.getSeconds() === 0 && now.getMinutes() % 5 === 0) {
                // 在屏幕中心区域 +/- 100 像素范围内随机移动
                var centerX = (napWin.width - clockContainer.width) / 2
                var centerY = (napWin.height - clockContainer.height) / 2
                clockContainer.x = centerX + (Math.random() * 200 - 100)
                clockContainer.y = centerY + (Math.random() * 200 - 100)
            }
        }
    }

    // -------------------------------------------------------------------------
    // 2. 状态提示与白噪音 (模拟)
    // -------------------------------------------------------------------------
    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20
        opacity: 0.3 // 整体保持低亮度
        
        // 状态文字
        Text {
            text: "正在午休 • 勿扰模式"
            color: "white"
            font.pixelSize: 16
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        // 提示文字
        Text {
            text: "长按屏幕 3 秒退出"
            color: "#888888"
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // -------------------------------------------------------------------------
    // 3. 长按退出交互
    // -------------------------------------------------------------------------
    
    // 进度环 (退出反馈)
    Rectangle {
        id: progressRing
        width: 100
        height: 100
        radius: 50
        color: "transparent"
        border.color: "white"
        border.width: 4
        anchors.centerIn: parent
        visible: false // 仅在按住时显示
        opacity: 0.5
        
        // 内部填充 (模拟进度)
        Rectangle {
            id: progressFill
            width: 0
            height: 0
            radius: width / 2
            color: "white"
            anchors.centerIn: parent
            opacity: 0.3
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        
        // 按下时启动计时
        onPressed: {
            progressRing.visible = true
            exitTimer.start()
            progressAnim.start()
        }
        
        // 松开时重置
        onReleased: {
            resetExitState()
        }
        
        // 退出重置
        onCanceled: {
            resetExitState()
        }
    }
    
    // 动画：长按时填充圆环
    PropertyAnimation {
        id: progressAnim
        target: progressFill
        properties: "width,height"
        from: 0
        to: 92 // 略小于外环
        duration: 3000 // 3秒
        easing.type: Easing.Linear
    }

    // 计时器：3秒后触发退出
    Timer {
        id: exitTimer
        interval: 3000
        repeat: false
        onTriggered: {
            // 调用 C++ 接口退出午休模式
            timerEngine.stopNap()
            resetExitState()
        }
    }
    
    function resetExitState() {
        exitTimer.stop()
        progressAnim.stop()
        progressRing.visible = false
        progressFill.width = 0
        progressFill.height = 0
    }
}
