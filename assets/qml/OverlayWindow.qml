import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Window {
    id: overlayWin
    visible: false
    // 强制全屏 + 置顶 + 无边框
    // Qt.WindowStaysOnTopHint: 确保在所有窗口之上
    // Qt.FramelessWindowHint: 去掉标题栏
    flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
    
    // 全屏显示
    visibility: Window.FullScreen
    
    // 背景色（初始颜色）
    color: "#2C3E50"

    // 公开方法：显示提醒
    function showReminder() {
        overlayWin.visible = true
        overlayWin.showFullScreen()
        overlayWin.raise()
    }

    // 简单的呼吸背景动画效果
    SequentialAnimation on color {
        loops: Animation.Infinite
        running: overlayWin.visible // 仅在显示时运行
        ColorAnimation { to: "#34495E"; duration: 4000 }
        ColorAnimation { to: "#2C3E50"; duration: 4000 }
    }

    Column {
        anchors.centerIn: parent
        spacing: 50

        Text {
            text: "🌿 休息时间到了"
            color: "white"
            font.pixelSize: 48
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "站起来走走，看看远方，放松一下眼睛和脊椎。"
            color: "#ECF0F1"
            font.pixelSize: 24
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            spacing: 40
            anchors.horizontalCenter: parent.horizontalCenter

            // 按钮：完成运动
            Button {
                text: "完成运动"
                font.pixelSize: 18
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "#2C3E50"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: "white"
                    radius: 10
                    implicitWidth: 160
                    implicitHeight: 60
                }
                onClicked: {
                    // 调用 C++ 接口重置计时
                    timerEngine.startWork() 
                    overlayWin.visible = false
                }
            }

            // 按钮：稍后提醒
            Button {
                text: "稍后提醒 (5分钟)"
                font.pixelSize: 18
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                    radius: 10
                    implicitWidth: 180
                    implicitHeight: 60
                }
                onClicked: {
                    // 调用 C++ 接口贪睡
                    timerEngine.snooze()
                    overlayWin.visible = false
                }
            }
        }
    }
}
