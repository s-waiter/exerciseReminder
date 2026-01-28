import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

// 主窗口/设置窗口
// 注意：该窗口默认隐藏，只有点击托盘或首次运行时才可能显示
Window {
    id: mainWindow
    width: 400
    height: 300
    visible: false // 初始隐藏，静默启动
    title: "久坐提醒助手设置"
    
    // 连接 C++ 托盘对象的信号
    Connections {
        target: trayIcon
        function onShowSettingsRequested() {
            mainWindow.visible = true
            mainWindow.raise()
            mainWindow.requestActivate()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "当前状态: " + timerEngine.statusText
            font.pixelSize: 18
            color: "#333333"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            // 简单的时间格式化
            property int mins: Math.floor(timerEngine.remainingSeconds / 60)
            property int secs: timerEngine.remainingSeconds % 60
            text: "剩余时间: " + mins + " 分 " + secs + " 秒"
            font.pixelSize: 24
            font.bold: true
            color: "#2C3E50"
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        // 分隔线
        Rectangle {
            width: parent.width * 0.8
            height: 1
            color: "#CCCCCC"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Button {
            text: "立即休息 (测试)"
            width: 200
            onClicked: overlay.showReminder()
        }
        
        Button {
            text: "隐藏到托盘"
            width: 200
            onClicked: mainWindow.hide()
        }
        
        Button {
            text: "重置计时"
            width: 200
            onClicked: timerEngine.startWork()
        }
    }

    // 实例化全屏提醒窗口组件
    // 这只是创建了对象，具体显示逻辑在 OverlayWindow 内部或由外部调用
    OverlayWindow {
        id: overlay
    }

    // 监听 C++ 计时器的提醒信号
    Connections {
        target: timerEngine
        function onReminderTriggered() {
            // 当倒计时结束时，显示全屏提醒
            overlay.showReminder()
        }
    }
}
