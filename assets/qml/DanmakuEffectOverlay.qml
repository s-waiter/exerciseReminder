import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Particles 2.0

Window {
    id: root
    visible: true
    // Fullscreen, transparent, click-through, always on top
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool | Qt.WindowTransparentForInput | Qt.WindowDoesNotAcceptFocus
    color: "transparent"
    
    // Explicit geometry properties to avoid 'parent' reference issues
    property int targetX: 0
    property int targetY: 0
    property int targetWidth: Screen.width
    property int targetHeight: Screen.height
    
    x: targetX
    y: targetY
    width: targetWidth
    height: targetHeight

    // External method to trigger effect at specific coordinates
    function playSliceEffect(xPos, yPos, color) {
        // Map global coordinates (xPos, yPos) to local coordinates of this Window
        // This is crucial for multi-monitor setups where the Window might be offset (e.g. x=1920)
        var localX = xPos - root.x;
        var localY = yPos - root.y;

        // Update emitters position and burst
        effectSource.x = localX
        effectSource.y = localY
        effectSource.particleColor = color
        
        // Trigger burst
        slashEmitter.burst(1)
        sparkEmitter.burst(20)
        shardEmitter.burst(10)
    }

    Item {
        id: effectSource
        x: 0; y: 0
        width: 1; height: 1
        property color particleColor: "#FFFFFF"
    }

    ParticleSystem {
        id: sys
        anchors.fill: parent
        
        // 1. Slash Line (The "Cut")
        ItemParticle {
            groups: ["slash"]
            delegate: Rectangle {
                width: 100
                height: 2
                color: "#FFFFFF"
                transform: Rotation { angle: Math.random() * 360 }
                opacity: 1
                SequentialAnimation on opacity {
                    NumberAnimation { to: 0; duration: 300 }
                }
            }
        }

        Emitter {
            id: slashEmitter
            group: "slash"
            emitRate: 0
            lifeSpan: 300
            size: 100
            // Fix: Direct coordinate binding instead of anchors to non-sibling
            x: effectSource.x
            y: effectSource.y
            velocity: AngleDirection { magnitude: 0 }
        }

        // 2. Sparks (The friction)
        ItemParticle {
            groups: ["sparks"]
            delegate: Rectangle {
                width: 3; height: 3
                color: effectSource.particleColor
                radius: 1.5
            }
        }
        
        Emitter {
            id: sparkEmitter
            group: "sparks"
            emitRate: 0
            lifeSpan: 500
            // Fix: Direct coordinate binding instead of anchors to non-sibling
            x: effectSource.x
            y: effectSource.y
            velocity: AngleDirection { angleVariation: 360; magnitude: 150; magnitudeVariation: 100 }
            acceleration: PointDirection { y: 200 } // Gravity
        }

        // 3. Shards (The debris)
        ItemParticle {
            groups: ["shards"]
            delegate: Rectangle {
                width: Math.random() * 6 + 2
                height: width
                color: effectSource.particleColor
                radius: width/2
                opacity: 0.8
                SequentialAnimation on opacity {
                    NumberAnimation { to: 0; duration: 600 }
                }
            }
        }
        
        Emitter {
            id: shardEmitter
            group: "shards"
            emitRate: 0
            lifeSpan: 600
            // Fix: Direct coordinate binding instead of anchors to non-sibling
            x: effectSource.x
            y: effectSource.y
            velocity: AngleDirection { angleVariation: 360; magnitude: 200; magnitudeVariation: 100 }
            acceleration: PointDirection { y: 300 }
        }
    }
}
