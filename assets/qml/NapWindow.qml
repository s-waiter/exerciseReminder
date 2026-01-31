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
            text: "长按屏幕 2 秒退出"
            color: "#888888"
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // -------------------------------------------------------------------------
    // 3. 长按退出交互
    // -------------------------------------------------------------------------
    
    // 退出进度 (0.0 - 1.0)
    property real exitProgress: 0.0

    // 绑定时钟的视觉反馈
    // 按住时：透明度变高 (变亮)，轻微放大
    // timeText 原透明度 0.2，目标 1.0
    // dateText 原透明度 0.15，目标 0.8
    // clockContainer 原缩放 1.0，目标 1.15
    Binding { target: timeText; property: "opacity"; value: 0.2 + (napWin.exitProgress * 0.8) }
    Binding { target: dateText; property: "opacity"; value: 0.15 + (napWin.exitProgress * 0.65) }
    Binding { target: clockContainer; property: "scale"; value: 1.0 + (napWin.exitProgress * 0.15) }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        
        // 按下时启动充电动画
        onPressed: {
            chargeAnim.start()
        }
        
        // 松开时回退
        onReleased: {
            chargeAnim.stop()
            dischargeAnim.start()
        }
        
        // 取消时回退
        onCanceled: {
            chargeAnim.stop()
            dischargeAnim.start()
        }
    }
    
    // 充电动画：2秒内达到 1.0
    NumberAnimation {
        id: chargeAnim
        target: napWin
        property: "exitProgress"
        to: 1.0
        duration: 2000 // 改为2秒
        easing.type: Easing.InOutQuad
        onFinished: {
            // 动画完成即触发退出
            timerEngine.stopNap()
            napWin.exitProgress = 0.0 // 重置
        }
    }

    // 放电动画：快速回退
    NumberAnimation {
        id: dischargeAnim
        target: napWin
        property: "exitProgress"
        to: 0.0
        duration: 300
        easing.type: Easing.OutQuad
    }

    function resetExitState() {
        chargeAnim.stop()
        napWin.exitProgress = 0.0
    }
}
