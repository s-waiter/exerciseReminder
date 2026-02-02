import QtQuick 2.15
import QtQuick.Controls 2.15

// Update Dialog Overlay
// ========================================================================
Rectangle {
    id: updateDialog
    visible: false
    width: 200 // 更小巧的宽度
    height: 140 // 更紧凑的高度
    radius: 16 // 更柔和的圆角
    color: "#F01B2A4E" // 增加不透明度，提升质感
    border.color: dialogMouseArea.containsMouse ? 
                  Qt.lighter(themeColor, 1.3) : 
                  Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.3)
    border.width: 1
    
    // 外部属性
    property color themeColor: "#00d2ff"

    // 悬浮放大特效
    scale: dialogMouseArea.containsMouse ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // 玻璃拟态光效 (顶部高光)
    Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.2)
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // 属性：下载状态
    property bool isDownloading: false
    
    function open() {
        visible = true
        isDownloading = false
        updateManager.resetStatus()
    }
    
    function close() {
        visible = false
    }

    // 阻止鼠标点击穿透 + 悬浮检测
    MouseArea {
        id: dialogMouseArea
        anchors.fill: parent
        hoverEnabled: true 
        onClicked: {} // 拦截点击
    }

    // 内容布局
    Column {
        anchors.centerIn: parent
        width: parent.width - 30
        spacing: 8

        // 标题与版本号组合
        Item {
            width: parent.width
            height: 30
            visible: !updateDialog.isDownloading
            
            Text {
                text: "发现新版本"
                color: "#8899AA"
                font.pixelSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
            }
            
            Text {
                text: "v" + updateManager.remoteVersion
                color: themeColor
                font.pixelSize: 18 // 放大版本号作为视觉重心
                font.bold: true
                font.family: "Segoe UI"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
            }
        }
        
        // 状态/进度区域
        Item {
            width: parent.width
            height: 40
            
            // 1. 简短询问 (非下载状态)
            Text {
                visible: !updateDialog.isDownloading
                text: "立即更新体验新功能?"
                color: "#DDDDDD"
                font.pixelSize: 11
                anchors.centerIn: parent
                opacity: 0.8
            }
            
            // 2. 进度条 (下载时显示)
            Rectangle {
                id: progressBar
                visible: updateDialog.isDownloading
                width: parent.width
                height: 4
                radius: 2
                color: "#33000000"
                anchors.centerIn: parent
                
                Rectangle {
                    height: parent.height
                    width: parent.width * updateManager.downloadProgress
                    color: themeColor
                    radius: 2
                }
            }
            
            // 3. 下载状态文本
            Text {
                visible: updateDialog.isDownloading
                text: updateManager.updateStatus
                color: "#AAAAAA"
                font.pixelSize: 9
                width: parent.width
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                anchors.top: progressBar.bottom
                anchors.topMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // 按钮组
        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !updateDialog.isDownloading

            // 暂不按钮 (纯文字，极简)
            Rectangle {
                width: 70
                height: 28
                color: "transparent"
                radius: 14
                
                Text {
                    text: "稍后"
                    color: hoverHandler1.hovered ? "#FFFFFF" : "#8899AA"
                    anchors.centerIn: parent
                    font.pixelSize: 11
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                HoverHandler { id: hoverHandler1 }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: updateDialog.close()
                }
            }

            // 立即更新按钮 (高亮胶囊)
            Rectangle {
                width: 80
                height: 28
                color: themeColor
                radius: 14
                // 简单的光泽感
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(themeColor, 1.2) }
                    GradientStop { position: 1.0; color: themeColor }
                }
                
                Text {
                    text: "更新"
                    // 优化对比度：使用深色文字 (#0B1015) 搭配高亮背景
                    color: "#0B1015" 
                    anchors.centerIn: parent
                    font.bold: true
                    font.pixelSize: 11
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        updateDialog.isDownloading = true
                        updateManager.startDownload("")
                    }
                }
            }
        }
    }
}
