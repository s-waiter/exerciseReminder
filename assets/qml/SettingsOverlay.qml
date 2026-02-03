import QtQuick 2.15
import QtQuick.Controls 2.15

// 设置弹窗 (Settings Overlay)
// ========================================================================
// 采用与 UpdateDialog 完全一致的视觉风格
Item {
    id: settingsOverlay
    anchors.fill: parent
    visible: false
    z: 200 // 确保在最上层
    
    // 外部属性接口
    property color themeColor: "#00d2ff"

    function open() { visible = true }
    function close() { visible = false }

    // 点击背景关闭
    MouseArea {
        anchors.fill: parent
        onClicked: settingsOverlay.close()
    }
    
    Rectangle {
        id: settingsDialog
        anchors.centerIn: parent
        width: 200 
        height: 180 
        radius: 16 
        color: "#F01B2A4E" // 增加不透明度，提升质感
        border.color: settingsDialogMouseArea.containsMouse ? 
                      Qt.lighter(themeColor, 1.3) : 
                      Qt.rgba(themeColor.r, themeColor.g, themeColor.b, 0.3)
        border.width: 1
        
        // 悬浮放大特效
        scale: settingsDialogMouseArea.containsMouse ? 1.05 : 1.0
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
        
        // 阻止点击穿透 + 悬浮检测
        MouseArea {
            id: settingsDialogMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {} // 拦截点击
        }
        
        // 内容
        Column {
            anchors.centerIn: parent
            width: parent.width - 30
            spacing: 12
            
            Text {
                text: "偏好设置"
                color: "white"
                font.pixelSize: 14
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            // 分割线
            Rectangle {
                width: parent.width
                height: 1
                color: "#22ffffff"
            }
            
            // 开机自启开关
            Item {
                width: parent.width
                height: 20
                
                Text {
                    text: "开机自启"
                    color: "#DDDDDD"
                    font.pixelSize: 12
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -2 // 向上微调 2px 以视觉对齐右侧开关
                }
                
                Switch {
                    checked: appConfig.autoStart
                    onToggled: appConfig.autoStart = checked
                    
                    scale: 0.7 // 稍微缩小开关以适应紧凑布局
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    
                    indicator: Rectangle {
                        implicitWidth: 40
                        implicitHeight: 20
                        radius: 10
                        color: parent.checked ? themeColor : "#33ffffff"
                        border.color: parent.checked ? themeColor : "#cccccc"
                        
                        Rectangle {
                            x: parent.parent.checked ? parent.width - width - 2 : 2
                            width: 16
                            height: 16
                            radius: 8
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on x { NumberAnimation { duration: 100 } }
                        }
                    }
                }
            }

            // 强制运动开关
            Item {
                width: parent.width
                height: 20
                
                Text {
                    text: "强制运动"
                    color: "#DDDDDD"
                    font.pixelSize: 12
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -2
                }
                
                Switch {
                    id: forcedExerciseSwitch
                    checked: appConfig.forcedExercise
                    onToggled: appConfig.forcedExercise = checked
                    
                    scale: 0.7
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    
                    indicator: Rectangle {
                        implicitWidth: 40
                        implicitHeight: 20
                        radius: 10
                        color: parent.checked ? themeColor : "#33ffffff"
                        border.color: parent.checked ? themeColor : "#cccccc"
                        
                        Rectangle {
                            x: parent.parent.checked ? parent.width - width - 2 : 2
                            width: 16
                            height: 16
                            radius: 8
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on x { NumberAnimation { duration: 100 } }
                        }
                    }
                }
            }

            // 强制运动时长设置 (仅当强制运动开启时显示)
            Item {
                width: parent.width
                height: 20
                visible: appConfig.forcedExercise
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                Text {
                    text: "强制时长"
                    color: "#999999"
                    font.pixelSize: 12
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    
                    // 减号按钮
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: "#33ffffff"
                        border.color: "#66ffffff"
                        border.width: 1
                        
                        Text {
                            text: "-"
                            color: "white"
                            anchors.centerIn: parent
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (appConfig.forcedExerciseDuration > 1) {
                                    appConfig.forcedExerciseDuration -= 1
                                }
                            }
                        }
                    }
                    
                    // 数值显示
                    Text {
                        text: appConfig.forcedExerciseDuration + " min"
                        color: "white"
                        font.pixelSize: 12
                        width: 35
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    // 加号按钮
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: "#33ffffff"
                        border.color: "#66ffffff"
                        border.width: 1
                        
                        Text {
                            text: "+"
                            color: "white"
                            anchors.centerIn: parent
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (appConfig.forcedExerciseDuration < 5) {
                                    appConfig.forcedExerciseDuration += 1
                                }
                            }
                        }
                    }
                }
            }

            // 分割线
            Rectangle {
                width: parent.width
                height: 1
                color: "#22ffffff"
            }

            // 活动分析按钮
            Rectangle {
                width: parent.width
                height: 30
                radius: 6
                color: activityBtnArea.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                
                Text {
                    text: "📊 查看活动轨迹与效率"
                    color: "white"
                    font.pixelSize: 12
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: activityBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        settingsOverlay.close()
                        mainWindow.showDashboard()
                    }
                }
            }
        }
        
        // 进入动画
        onVisibleChanged: {
            if (visible) {
                enterAnim.restart()
            }
        }
        
        ParallelAnimation {
            id: enterAnim
            NumberAnimation { target: settingsDialog; property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
            NumberAnimation { target: settingsDialog; property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutBack }
        }
    }
}
