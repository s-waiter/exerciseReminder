import QtQuick 2.15
import QtQuick.Particles 2.0
import QtGraphicalEffects 1.15
import QtQuick.Shapes 1.15

Item {
    id: root
    anchors.fill: parent
    visible: false 
    z: 100 

    property string hourText: "12"
    
    // 全局特效配置
    property int currentModeIndex: 0
    property int totalModes: modeComponents.count

    function trigger(isManual) {
        var date = new Date()
        hourText = Qt.formatDateTime(date, "H") 
        
        if (isManual) {
            currentModeIndex = (currentModeIndex + 1) % totalModes
            console.log("Manual Trigger Chime [" + currentModeIndex + "]: " + modeComponents.nameAt(currentModeIndex))
        } else {
            currentModeIndex = Math.floor(Math.random() * totalModes)
        }
        
        visible = true
        effectLoader.sourceComponent = modeComponents.objectAt(currentModeIndex)
    }

    function finishEffect() {
        root.visible = false
        effectLoader.sourceComponent = undefined 
    }

    Loader {
        id: effectLoader
        anchors.fill: parent
        onLoaded: {
            if (item && item.start) {
                item.start()
            }
        }
    }

    QtObject {
        id: modeComponents
        property var list: [
            compHologram,       // 0: 全息立方
            compSingularity,    // 1: 引力奇点
            compMechanical,     // 2: 精密机械
            compCyberGrid,      // 3: 赛博网格
            compDigitalRain,    // 4: 数据雨
            compNeonPulse,      // 5: 霓虹脉冲
            compRadar,          // 6: 雷达扫描
            compCircuit,        // 7: 能量回路
            compDNA,            // 8: 生命螺旋
            compHexShield,      // 9: 蜂巢护盾
            compPlasma,         // 10: 等离子核
            compTerminal,       // 11: 终端指令
            compQuantum,        // 12: 量子核心 (Replaced Eclipse)
            compAudioViz,       // 13: 霓虹视界 (Neon Synthwave)
            compVortex,         // 14: 时空漩涡
            compIris,           // 15: 机械光圈
            compGlitch,         // 16: 数据崩坏 (Cyber Data Corruption)
            compVoxel,          // 17: 体素重构
            compSonar,          // 18: 深海声呐
            compNeural,         // 19: 神经网络
            compScanner,        // 20: 生物识别 (Biometric Security)
            compForcefield,     // 21: 等离子护盾 (Plasma Shield)
            compCrystal,        // 22: 水晶生长
            compLiquid          // 23: 星云流体 (Nebula Fluid)
        ]
        property int count: list.length
        property var names: [
            "Hologram (全息立方)", "Singularity (引力奇点)", "Mechanical (精密机械)", "CyberGrid (赛博网格)",
            "DigitalRain (数据雨)", "NeonPulse (霓虹脉冲)", "Radar (雷达扫描)", "Circuit (能量回路)",
            "DNA (生命螺旋)", "HexShield (蜂巢护盾)", "Plasma (等离子核)", "Terminal (终端指令)",
            "Quantum (量子核心)", "Neon Synthwave (霓虹视界)", "Vortex (时空漩涡)", "Iris (机械光圈)",
            "Cyber Data Corruption (数据崩坏)", "Voxel (体素重构)", "Sonar (深海声呐)", "Neural (神经网络)",
            "Biometric Security (生物识别)", "Plasma Shield (等离子护盾)", "Crystal (水晶生长)", "Nebula Fluid (星云流体)"
        ]
        function objectAt(index) { return list[index] }
        function nameAt(index) { return names[index] }
    }

    // ========================================================================
    // 0. HOLOGRAM CUBE (全息立方) - OPTIMIZED
    // ========================================================================
    Component {
        id: compHologram
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            
            // Projector Base
            Rectangle {
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.8; height: 4; radius: 2
                color: "#003366"; opacity: 0.8
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "#00ffff"; transparentBorder: true }
            }
            
            // Hologram Beam (Scanlines)
            Canvas {
                id: beamCanvas
                anchors.fill: parent
                property real scanY: 0
                onScanYChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    // Scanline Gradient
                    var grad = ctx.createLinearGradient(0, height, 0, 0);
                    grad.addColorStop(0, "rgba(0, 255, 255, 0)");
                    grad.addColorStop(0.5, "rgba(0, 255, 255, 0.1)");
                    grad.addColorStop(1, "rgba(0, 255, 255, 0)");
                    ctx.fillStyle = grad;
                    ctx.fillRect(0, 0, width, height);
                    
                    // Moving scan bar
                    ctx.fillStyle = "rgba(0, 255, 255, 0.3)";
                    ctx.fillRect(0, height - scanY, width, 5);
                }
            }

            // 3D Cube Canvas
            Canvas {
                id: cubeCanvas
                anchors.fill: parent
                property real angle: 0
                onAngleChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var cx = width/2, cy = height/2;
                    var size = width/3;
                    
                    var vertices = [
                        {x:-1, y:-1, z:-1}, {x:1, y:-1, z:-1}, {x:1, y:1, z:-1}, {x:-1, y:1, z:-1},
                        {x:-1, y:-1, z:1}, {x:1, y:-1, z:1}, {x:1, y:1, z:1}, {x:-1, y:1, z:1}
                    ];
                    
                    var edges = [
                        [0,1], [1,2], [2,3], [3,0], // Back face
                        [4,5], [5,6], [6,7], [7,4], // Front face
                        [0,4], [1,5], [2,6], [3,7]  // Connecting lines
                    ];
                    
                    ctx.strokeStyle = "#00ffff";
                    ctx.lineWidth = 2;
                    ctx.shadowColor = "#00ffff"; ctx.shadowBlur = 10;
                    ctx.lineJoin = "round";
                    
                    ctx.beginPath();
                    var projected = [];
                    
                    // Rotate
                    var cosA = Math.cos(angle);
                    var sinA = Math.sin(angle);
                    var cosB = Math.cos(angle * 0.5);
                    var sinB = Math.sin(angle * 0.5);
                    
                    for(var i=0; i<vertices.length; i++) {
                        var v = vertices[i];
                        // Rotate Y
                        var x1 = v.x * cosA - v.z * sinA;
                        var z1 = v.z * cosA + v.x * sinA;
                        // Rotate X
                        var y2 = v.y * cosB - z1 * sinB;
                        var z2 = z1 * cosB + v.y * sinB;
                        
                        // Project
                        var scale = size / (2 - z2 * 0.5); // Perspective
                        var px = cx + x1 * scale;
                        var py = cy + y2 * scale;
                        projected.push({x: px, y: py});
                    }
                    
                    for(var j=0; j<edges.length; j++) {
                        var e = edges[j];
                        var p1 = projected[e[0]];
                        var p2 = projected[e[1]];
                        ctx.moveTo(p1.x, p1.y);
                        ctx.lineTo(p2.x, p2.y);
                    }
                    ctx.stroke();
                }
            }
            
            Text {
                id: holoText
                anchors.centerIn: parent; text: root.hourText
                font.family: "Impact"; font.pixelSize: parent.width * 0.6; font.bold: true
                color: "#E6FFFFFF"; style: Text.Outline; styleColor: "#003366"
                opacity: 0; scale: 0
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "#00ffff"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                ScriptAction { script: { beamCanvas.scanY = 0; cubeCanvas.angle = 0; holoText.opacity = 0; } }
                ParallelAnimation {
                    NumberAnimation { target: beamCanvas; property: "scanY"; to: root.height; duration: 1000 }
                    NumberAnimation { target: cubeCanvas; property: "angle"; to: Math.PI * 2; duration: 2500 }
                    NumberAnimation { target: holoText; property: "opacity"; to: 1; duration: 500 }
                    NumberAnimation { target: holoText; property: "scale"; from: 0; to: 1; duration: 500; easing.type: Easing.OutBack }
                }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 1. SINGULARITY (引力奇点) - FIX & OPTIMIZED
    // ========================================================================
    Component {
        id: compSingularity
        Item {
            anchors.fill: parent
            function start() { 
                blackHoleCanvas.distortion = 0.01
                blackHoleCanvas.angle = 0
                anim.restart() 
            }
            
            Rectangle { anchors.fill: parent; color: "#000000"; radius: width/2 } // Absolute black

            Canvas {
                id: blackHoleCanvas
                anchors.fill: parent
                property real distortion: 0.01
                property real angle: 0
                
                onDistortionChanged: requestPaint()
                onAngleChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    var r = width/2 * distortion;
                    
                    if (r < 1) return;

                    // 1. Accretion Disk (Rotating Gradient)
                    ctx.save();
                    ctx.translate(cx, cy);
                    ctx.rotate(angle * Math.PI / 180);
                    
                    var diskGrad = ctx.createRadialGradient(0, 0, r * 0.5, 0, 0, r * 1.5);
                    diskGrad.addColorStop(0, "transparent");
                    diskGrad.addColorStop(0.2, "rgba(255, 100, 50, 1)"); // Hot inner rim
                    diskGrad.addColorStop(0.5, "rgba(255, 150, 0, 0.6)"); // Orange body
                    diskGrad.addColorStop(1, "rgba(255, 200, 100, 0)"); // Fade out
                    
                    ctx.fillStyle = diskGrad;
                    ctx.beginPath();
                    ctx.arc(0, 0, r * 1.6, 0, Math.PI*2);
                    ctx.fill();
                    
                    // 2. Relativistic Beaming (Doppler effect simulation - brighter on one side)
                    var beamGrad = ctx.createLinearGradient(-r, 0, r, 0);
                    beamGrad.addColorStop(0, "rgba(255, 255, 255, 0.8)");
                    beamGrad.addColorStop(1, "rgba(255, 100, 50, 0.2)");
                    ctx.globalCompositeOperation = "lighter";
                    ctx.fillStyle = beamGrad;
                    ctx.beginPath();
                    ctx.arc(0, 0, r * 1.4, 0, Math.PI*2);
                    ctx.fill();
                    
                    ctx.restore();
                    
                    // 3. Photon Ring (Sharp bright circle)
                    if(distortion > 0.1) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, r * 0.6, 0, Math.PI*2);
                        ctx.strokeStyle = "#ffffff";
                        ctx.lineWidth = 2;
                        ctx.shadowColor = "#ffffff"; 
                        ctx.shadowBlur = 10;
                        ctx.stroke();
                        ctx.shadowBlur = 0;
                    }

                    // 4. Event Horizon (The Void)
                    ctx.globalCompositeOperation = "source-over";
                    ctx.fillStyle = "black";
                    ctx.beginPath();
                    ctx.arc(cx, cy, r * 0.5, 0, Math.PI*2);
                    ctx.fill();
                }
            }
            
            Timer {
                interval: 30; running: true; repeat: true
                onTriggered: blackHoleCanvas.angle += 3
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                font.family: "Impact"; font.pixelSize: parent.width*0.65; font.bold: true
                color: "white"; style: Text.Outline; styleColor: "#ff4400"
                opacity: 0; scale: 0; z: 10
                layer.enabled: true
                layer.effect: Glow { samples: 20; color: "#ff8800"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: blackHoleCanvas; property: "distortion"; from: 0.01; to: 1; duration: 1000; easing.type: Easing.OutExpo }
                ParallelAnimation {
                    NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 300 }
                    NumberAnimation { target: txt; property: "scale"; to: 1; duration: 600; easing.type: Easing.OutBack }
                }
                PauseAnimation { duration: 3000 }
                NumberAnimation { target: blackHoleCanvas; property: "distortion"; to: 0.01; duration: 500; easing.type: Easing.InExpo }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 2. MECHANICAL (精密机械) - OPTIMIZED
    // ========================================================================
    Component {
        id: compMechanical
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            
            Canvas {
                id: gearCanvas
                anchors.fill: parent
                property real angle: 0
                onAngleChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var cx = width/2, cy = height/2;
                    
                    // Metallic Gradient
                    var gradGold = ctx.createLinearGradient(0, 0, width, height);
                    gradGold.addColorStop(0, "#FDB931"); 
                    gradGold.addColorStop(0.3, "#FFFFAC");
                    gradGold.addColorStop(0.6, "#D1B464");
                    gradGold.addColorStop(1, "#FDB931");

                    var gradSteel = ctx.createLinearGradient(0, 0, width, height);
                    gradSteel.addColorStop(0, "#888888"); 
                    gradSteel.addColorStop(0.5, "#eeeeee");
                    gradSteel.addColorStop(1, "#666666");

                    // 1. Back Gear (Steel, Counter-Rotating)
                    ctx.save();
                    ctx.translate(cx, cy);
                    ctx.rotate(-angle * 0.5 * Math.PI / 180);
                    drawGear(ctx, 0, 0, width/2 * 0.95, width/2 * 0.8, 12, gradSteel);
                    ctx.restore();

                    // 2. Main Gear (Gold, Rotating)
                    ctx.save();
                    ctx.translate(cx, cy);
                    ctx.rotate(angle * Math.PI / 180);
                    drawGear(ctx, 0, 0, width/2 * 0.75, width/2 * 0.55, 8, gradGold);
                    
                    // Rivets on Main Gear
                    ctx.fillStyle = "#5E4B25";
                    for(var i=0; i<4; i++) {
                         ctx.save();
                         ctx.rotate(i * Math.PI/2);
                         ctx.beginPath();
                         ctx.arc(width/2 * 0.65, 0, 3, 0, Math.PI*2);
                         ctx.fill();
                         ctx.restore();
                    }
                    ctx.restore();
                    
                    // 3. Center Axle
                    ctx.beginPath();
                    ctx.arc(cx, cy, width/2 * 0.2, 0, Math.PI*2);
                    ctx.fillStyle = gradSteel;
                    ctx.fill();
                    ctx.strokeStyle = "#444"; ctx.lineWidth = 1; ctx.stroke();
                }

                function drawGear(ctx, x, y, outerR, innerR, teeth, fillStyle) {
                    ctx.beginPath();
                    for (var i = 0; i < teeth; i++) {
                        var a = (Math.PI * 2 * i) / teeth;
                        var step = (Math.PI * 2) / teeth;
                        
                        var toothWidth = step * 0.4;
                        var slope = step * 0.05;
                        
                        var a1 = a; 
                        var a2 = a + slope; 
                        var a3 = a + toothWidth - slope; 
                        var a4 = a + toothWidth; 
                        
                        if(i===0) ctx.moveTo(x + innerR * Math.cos(a1), y + innerR * Math.sin(a1));
                        else ctx.lineTo(x + innerR * Math.cos(a1), y + innerR * Math.sin(a1));
                        
                        ctx.lineTo(x + outerR * Math.cos(a2), y + outerR * Math.sin(a2));
                        ctx.lineTo(x + outerR * Math.cos(a3), y + outerR * Math.sin(a3));
                        ctx.lineTo(x + innerR * Math.cos(a4), y + innerR * Math.sin(a4));
                    }
                    ctx.closePath();
                    
                    ctx.shadowColor = "black"; ctx.shadowBlur = 5;
                    ctx.fillStyle = fillStyle;
                    ctx.fill();
                    ctx.shadowBlur = 0;
                    
                    ctx.strokeStyle = "rgba(0,0,0,0.3)"; ctx.lineWidth = 1; ctx.stroke();
                }
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                font.family: "Courier New"; font.pixelSize: parent.width*0.55; font.bold: true
                color: "#FFFFFF"; style: Text.Outline; styleColor: "#333333" 
                opacity: 0
                layer.enabled: true
                layer.effect: Glow { samples: 15; color: "#FDB931"; transparentBorder: true }
            }

            SequentialAnimation {
                id: anim
                NumberAnimation { target: gearCanvas; property: "angle"; from: 0; to: 180; duration: 2000; easing.type: Easing.InOutCubic }
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 300 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 3. CYBER GRID (赛博网格)
    // ========================================================================
    Component {
        id: compCyberGrid
        Item {
            anchors.fill: parent
            clip: true
            function start() { anim.restart() }
            
            Rectangle { anchors.fill: parent; color: "#1a0033"; radius: width/2 } // Deep purple bg
            
            Item {
                id: gridContainer
                width: parent.width; height: parent.height
                transform: [
                    Rotation { origin.x: width/2; origin.y: height/2; axis.x: 1; angle: 60 },
                    Translate { y: 20 }
                ]
                
                Canvas {
                    anchors.fill: parent
                    property real offset: 0
                    onOffsetChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "#ff00ff"; // Neon Pink
                        ctx.lineWidth = 2;
                        ctx.shadowColor = "#ff00ff"; ctx.shadowBlur = 10;
                        
                        for(var x=0; x<=width; x+=20) {
                            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
                        }
                        for(var y=offset; y<=height; y+=20) {
                            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
                        }
                    }
                }
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                font.family: "Impact"; font.pixelSize: parent.width*0.6
                color: "#00ffff"; style: Text.Outline; styleColor: "#ff00ff"
                opacity: 0; scale: 0.5
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "#ff00ff"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                ParallelAnimation {
                    NumberAnimation { target: gridContainer.children[0]; property: "offset"; from: 0; to: 20; duration: 500; loops: 4 }
                    NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                    NumberAnimation { target: txt; property: "scale"; to: 1; duration: 1000; easing.type: Easing.OutElastic }
                }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 4. DIGITAL RAIN (数据雨)
    // ========================================================================
    Component {
        id: compDigitalRain
        Item {
            anchors.fill: parent; clip: true
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "black"; radius: width/2 }
            
            Row {
                anchors.centerIn: parent; spacing: 5
                Repeater {
                    model: 10
                    Column {
                        id: rainCol
                        property int speed: 500 + Math.random() * 1000
                        width: 10
                        Repeater {
                            model: 12
                            Text {
                                text: Math.random() > 0.5 ? "1" : "0"
                                color: index === 0 ? "#ccffcc" : "#00ff00"
                                font.pixelSize: 12; font.bold: true
                                opacity: 1 - index/12
                            }
                        }
                        y: -height
                        NumberAnimation on y { from: -100; to: 100; duration: rainCol.speed; loops: Animation.Infinite }
                    }
                }
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                font.family: "Consolas"; font.bold: true; font.pixelSize: parent.width*0.65
                color: "white"; style: Text.Outline; styleColor: "#003300"
                opacity: 0
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "#00ff00"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                PauseAnimation { duration: 500 }
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 5. NEON PULSE (霓虹脉冲) - OPTIMIZED
    // ========================================================================
    Component {
        id: compNeonPulse
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#000510"; radius: width/2 }
            
            Canvas {
                id: pulseCanvas
                anchors.fill: parent
                property real t: 0
                onTChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var cx = width/2, cy = height/2;
                    ctx.globalCompositeOperation = "lighter"; // Additive blending
                    
                    var colors = ["#00ffff", "#ff00ff", "#00ff00"];
                    var shapes = [3, 4, 6]; // Triangle, Square, Hexagon
                    
                    for(var i=0; i<3; i++) {
                        var r = (width/3) * (1 + 0.5 * Math.sin(t * 2 + i));
                        var angle = t * (i%2==0?1:-1) + i * Math.PI/3;
                        
                        // 性能优化：移除 Canvas shadowBlur (性能杀手)
                        // 改用双层描边模拟霓虹发光效果
                        
                        // 1. 外层光晕 (半透明粗线)
                        ctx.beginPath();
                        var sides = shapes[i];
                        for(var j=0; j<=sides; j++) {
                            var theta = angle + j * 2 * Math.PI / sides;
                            var x = cx + r * Math.cos(theta);
                            var y = cy + r * Math.sin(theta);
                            if(j==0) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        ctx.closePath();
                        
                        ctx.lineWidth = 8;
                        ctx.strokeStyle = colors[i];
                        ctx.globalAlpha = 0.3; // 半透明
                        ctx.stroke();
                        
                        // 2. 内层核心 (高亮细线)
                        ctx.lineWidth = 2;
                        ctx.strokeStyle = "white";
                        ctx.globalAlpha = 1.0;
                        ctx.stroke();
                    }
                    
                    // Center Pulse
                    var pulseR = (width/4) * (0.8 + 0.2 * Math.sin(t * 5));
                    ctx.fillStyle = "rgba(0, 255, 255, 0.1)";
                    ctx.beginPath();
                    ctx.arc(cx, cy, pulseR, 0, Math.PI*2);
                    ctx.fill();
                }
            }
            Timer {
                interval: 50; running: true; repeat: true
                onTriggered: pulseCanvas.t += 0.05
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                font.pixelSize: parent.width*0.65; font.bold: true; font.family: "Verdana"
                color: "white"; style: Text.Outline; styleColor: "#008888"
                opacity: 0
                layer.enabled: true
                layer.effect: Glow { samples: 20; color: "cyan"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                PauseAnimation { duration: 200 }
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                PauseAnimation { duration: 3000 } 
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 6. RADAR (雷达扫描) - HOLOGRAPHIC TACTICAL GLOBE
    // ========================================================================
    Component {
        id: compRadar
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#000810"; radius: width/2 } // Dark Navy

            Canvas {
                id: radarCanvas
                anchors.fill: parent
                property real angle: 0
                property real scanY: 0
                onAngleChanged: requestPaint()
                onScanYChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    var r = width/2 * 0.75;
                    
                    ctx.globalCompositeOperation = "lighter";
                    
                    // 1. 3D Wireframe Globe (Rotating)
                    ctx.strokeStyle = "rgba(0, 180, 255, 0.4)";
                    ctx.lineWidth = 1.5;
                    
                    var meridians = 8; // Optimized: Reduced from 12
                    for(var i=0; i<meridians; i++) {
                        var theta = (i/meridians) * Math.PI*2 + angle;
                        var scaleX = Math.cos(theta);
                        
                        ctx.save();
                        ctx.translate(cx, cy);
                        ctx.scale(scaleX, 1);
                        ctx.beginPath();
                        ctx.arc(0, 0, r, 0, Math.PI*2);
                        ctx.stroke();
                        ctx.restore();
                    }
                    
                    // Equator & Tropics
                    ctx.beginPath();
                    ctx.ellipse(cx, cy, r, r*0.3, 0, 0, Math.PI*2); // Tilted equator appearance
                    ctx.stroke();
                    
                    // 2. Active Scan Plane (Horizontal Laser)
                    var scanH = height * scanY;
                    var scanW = Math.sqrt(Math.pow(r,2) - Math.pow(Math.abs(cy - scanH), 2)); // Clip to circle?
                    // Simplified scan line across screen
                    ctx.strokeStyle = "#00ffff";
                    ctx.lineWidth = 2;
                    // Removed shadowBlur for performance
                    ctx.beginPath();
                    ctx.moveTo(0, scanH);
                    ctx.lineTo(width, scanH);
                    ctx.stroke();
                    
                    // 3. Floating HUD Elements
                    ctx.shadowBlur = 0;
                    ctx.fillStyle = "rgba(0, 255, 255, 0.5)";
                    ctx.font = "10px monospace";
                    ctx.fillText("TGT_LOCK: " + Math.floor(angle*100), 10, height/2);
                    ctx.fillText("SEC_Z: " + Math.floor(scanY*100) + "%", width-60, height/2);
                    
                    // 4. Detected Satellite
                    var satAngle = angle * 3;
                    var satX = cx + Math.cos(satAngle) * r * 1.3;
                    var satY = cy + Math.sin(satAngle) * r * 0.3;
                    
                    ctx.fillStyle = "#ff3333";
                    ctx.shadowBlur = 0; // Removed shadowBlur
                    ctx.beginPath(); ctx.arc(satX, satY, 4, 0, Math.PI*2); ctx.fill();
                    // Connector line
                    ctx.strokeStyle = "rgba(255, 50, 50, 0.5)";
                    ctx.lineWidth = 1;
                    ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(satX, satY); ctx.stroke();
                }
            }
            
            Timer {
                interval: 50; running: true; repeat: true // Optimized: 30ms -> 50ms
                onTriggered: {
                    radarCanvas.angle += 0.02
                }
            }

            // Failsafe Timer: Ensure effect closes even if animation gets stuck
            Timer {
                interval: 5000; running: true; repeat: false
                onTriggered: {
                    console.log("Radar Failsafe Triggered")
                    root.finishEffect()
                }
            }

            // Independent Scan Animation (Fixes infinite loop bug)
            NumberAnimation {
                target: radarCanvas
                property: "scanY"
                from: 0; to: 1
                duration: 1500
                loops: Animation.Infinite
                easing.type: Easing.InOutSine
                running: true
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                color: "white"; font.pixelSize: parent.width*0.6; font.bold: true
                font.family: "Arial Black"
                style: Text.Outline; styleColor: "#003366"
                opacity: 0
                layer.enabled: true
                layer.effect: Glow { samples: 15; color: "#00aaff"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 7. CIRCUIT (能量回路)
    // ========================================================================
    Component {
        id: compCircuit
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#000510"; radius: width/2 }
            
            Canvas {
                id: circuitCanvas
                anchors.fill: parent
                property real progress: 0
                onProgressChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "#00aaff";
                    ctx.lineWidth = 3;
                    ctx.lineCap = "round";
                    ctx.shadowColor = "#00aaff"; ctx.shadowBlur = 8;
                    
                    var cx = width/2, cy = height/2;
                    
                    ctx.beginPath();
                    ctx.moveTo(cx, height);
                    ctx.lineTo(cx, cy + 30);
                    ctx.lineTo(cx + 30, cy);
                    ctx.stroke();
                    
                    ctx.beginPath();
                    ctx.moveTo(0, cy);
                    ctx.lineTo(cx - 30, cy);
                    ctx.lineTo(cx, cy - 30);
                    ctx.stroke();
                    
                    if (progress > 0) {
                        ctx.fillStyle = "white";
                        ctx.shadowBlur = 15;
                        ctx.beginPath();
                        ctx.arc(cx, cy + 30 - progress*60, 5, 0, Math.PI*2); 
                        ctx.fill();
                    }
                }
            }
            
            Rectangle {
                id: chip
                anchors.centerIn: parent; width: parent.width * 0.6; height: width; 
                color: "#002244"; border.color: "#00aaff"; border.width: 2
                radius: 10
                Text { 
                    anchors.centerIn: parent; text: root.hourText; color: "white"; 
                    font.pixelSize: parent.width * 0.7; font.bold: true; font.family: "Consolas"
                    style: Text.Outline; styleColor: "#00aaff"
                }
                opacity: 0
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "#00aaff"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: circuitCanvas; property: "progress"; from: 0; to: 1; duration: 500 }
                NumberAnimation { target: chip; property: "opacity"; to: 1; duration: 200 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 8. DNA (生命螺旋) - GENOMIC SEQUENCER - OPTIMIZED
    // ========================================================================
    Component {
        id: compDNA
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#0a001a"; radius: width/2 } // Deep Void Purple

            Canvas {
                id: dnaCanvas
                anchors.fill: parent
                property real t: 0
                
                // Optimized: Pre-calculate genetic code positions
                property var geneticCode: []
                function initCode() {
                    geneticCode = []
                    var chars = ["A", "T", "C", "G"]
                    for(var k=0; k<5; k++) {
                        geneticCode.push({
                            txt: chars[Math.floor(Math.random()*4)],
                            x: Math.random() * width,
                            y: Math.random() * height,
                            offset: Math.random() * 100
                        })
                    }
                }
                onWidthChanged: initCode()
                onHeightChanged: initCode()

                onTChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    
                    ctx.globalCompositeOperation = "lighter";
                    
                    var count = 8; // Optimized: Reduced from 12
                    var spacing = height / (count + 2);
                    var radius = width * 0.35;
                    
                    // Draw Double Helix
                    for(var i=0; i<count; i++) {
                        var y = (i + 1) * spacing;
                        var angle = t + i * 0.6; // Faster twist
                        
                        var xOffset = Math.sin(angle) * radius;
                        var z = Math.cos(angle); 
                        var scale = 0.8 + z * 0.4;
                        var alpha = 0.5 + z * 0.5;
                        
                        var x1 = cx + xOffset;
                        var x2 = cx - xOffset;
                        
                        // Connector rungs
                        ctx.strokeStyle = "rgba(0, 255, 200, " + (alpha * 0.3) + ")";
                        ctx.lineWidth = 1 * scale;
                        ctx.beginPath(); ctx.moveTo(x1, y); ctx.lineTo(x2, y); ctx.stroke();
                        
                        // Strand 1 (Neon Blue)
                        ctx.fillStyle = "rgba(0, 150, 255, " + alpha + ")";
                        // Optimized: Removed expensive shadowBlur
                        ctx.beginPath(); ctx.arc(x1, y, 5 * scale, 0, Math.PI*2); ctx.fill();
                        
                        // Strand 2 (Neon Pink)
                        ctx.fillStyle = "rgba(255, 0, 200, " + alpha + ")";
                        // Optimized: Removed expensive shadowBlur
                        ctx.beginPath(); ctx.arc(x2, y, 5 * scale, 0, Math.PI*2); ctx.fill();
                    }
                    
                    // Floating Genetic Code
                    ctx.fillStyle = "rgba(255, 255, 255, 0.8)";
                    ctx.font = "10px monospace";
                    
                    if(geneticCode.length === 0) initCode();
                    
                    for(var k=0; k<geneticCode.length; k++) {
                        var g = geneticCode[k];
                        // Gentle float effect
                        var floatY = g.y + Math.sin(t + g.offset) * 5;
                        ctx.fillText(g.txt, g.x, floatY);
                    }
                }
            }
            
            Timer {
                interval: 60; running: true; repeat: true // Optimized: 50ms -> 60ms
                onTriggered: dnaCanvas.t += 0.08
            }

            // Failsafe Timer
            Timer {
                interval: 5000; running: true; repeat: false
                onTriggered: root.finishEffect()
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                color: "white"; font.pixelSize: parent.width*0.6; font.bold: true
                font.family: "Verdana"
                style: Text.Outline; styleColor: "#aa00cc"
                opacity: 0
                layer.enabled: true
                layer.effect: Glow { samples: 20; color: "#aa00ff"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 9. HEX SHIELD (蜂巢护盾)
    // ========================================================================
    Component {
        id: compHexShield
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            
            Canvas {
                id: hexCanvas
                anchors.fill: parent
                property real reveal: 0
                onRevealChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "#ffaa00";
                    ctx.lineWidth = 2;
                    ctx.shadowColor = "#ffaa00"; ctx.shadowBlur = 5;
                    ctx.fillStyle = "rgba(255, 170, 0, 0.2)";
                    
                    var r = 15;
                    var dx = r * 1.5;
                    var dy = r * Math.sqrt(3);
                    
                    for(var y=0; y<height+r; y+=dy) {
                        for(var x=0; x<width+r; x+=dx) {
                            if (Math.random() > reveal) continue; 
                            
                            ctx.beginPath();
                            for(var i=0; i<6; i++) {
                                ctx.lineTo(x + r*Math.cos(i*Math.PI/3), y + r*Math.sin(i*Math.PI/3));
                            }
                            ctx.closePath();
                            ctx.stroke();
                            ctx.fill();
                        }
                    }
                }
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                font.pixelSize: parent.width * 0.6; font.bold: true; font.family: "Arial Black"
                color: "#ffaa00"; style: Text.Outline; styleColor: "black"
                opacity: 0
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "#ffaa00"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: hexCanvas; property: "reveal"; from: 0; to: 1; duration: 1000 }
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 10. PLASMA CORE (等离子核) - TOKAMAK REACTOR
    // ========================================================================
    Component {
        id: compPlasma
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#000510"; radius: width/2 }

            Canvas {
                id: plasmaCanvas
                anchors.fill: parent
                property real t: 0
                property real power: 0
                onTChanged: requestPaint()
                onPowerChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    var r = width/2;
                    
                    ctx.globalCompositeOperation = "lighter";

                    // 1. Magnetic Field Rings (Tokamak Style)
                    for(var i=0; i<3; i++) {
                        ctx.save();
                        ctx.translate(cx, cy);
                        ctx.rotate(t * (i+1) * 0.5 + i * Math.PI/3);
                        
                        var ringR = r * (0.6 + i * 0.15) * power;
                        
                        // Ring Gradient
                        var grad = ctx.createLinearGradient(-ringR, -ringR, ringR, ringR);
                        grad.addColorStop(0, "rgba(0, 255, 255, 0.1)");
                        grad.addColorStop(0.5, "rgba(0, 150, 255, 0.8)");
                        grad.addColorStop(1, "rgba(0, 255, 255, 0.1)");
                        
                        ctx.strokeStyle = grad;
                        ctx.lineWidth = 5;
                        ctx.beginPath();
                        ctx.arc(0, 0, ringR, 0, Math.PI*2);
                        ctx.stroke();
                        
                        // Energy Particles on Ring
                        var particleAngle = t * 3 + i;
                        var px = ringR * Math.cos(particleAngle);
                        var py = ringR * Math.sin(particleAngle);
                        ctx.fillStyle = "white";
                        ctx.shadowColor = "#00ffff"; ctx.shadowBlur = 15;
                        ctx.beginPath(); ctx.arc(px, py, 4, 0, Math.PI*2); ctx.fill();
                        ctx.shadowBlur = 0;
                        
                        ctx.restore();
                    }
                    
                    // 2. Central Fusion Core (Sun-like)
                    var coreR = r * 0.4 * power;
                    var coreGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, Math.max(0.1, coreR));
                    coreGrad.addColorStop(0, "white");
                    coreGrad.addColorStop(0.3, "#00ffff");
                    coreGrad.addColorStop(0.7, "#0055ff");
                    coreGrad.addColorStop(1, "transparent");
                    
                    ctx.fillStyle = coreGrad;
                    ctx.beginPath();
                    ctx.arc(cx, cy, coreR, 0, Math.PI*2);
                    ctx.fill();
                    
                    // 3. Unstable Arcs
                    if(power > 0.5) {
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.6)";
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        for(var k=0; k<8; k++) {
                             var a = t * 2 + k * Math.PI/4;
                             var dist = coreR * (0.8 + 0.4 * Math.random());
                             ctx.moveTo(cx + coreR * Math.cos(a), cy + coreR * Math.sin(a));
                             ctx.lineTo(cx + dist * Math.cos(a), cy + dist * Math.sin(a));
                        }
                        ctx.stroke();
                    }
                }
            }
            Timer {
                interval: 30; running: true; repeat: true
                onTriggered: plasmaCanvas.t += 0.05
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                font.pixelSize: parent.width * 0.6; font.bold: true; font.family: "Verdana"
                color: "white"; style: Text.Outline; styleColor: "#003366"
                opacity: 0
                z: 10
                layer.enabled: true
                layer.effect: Glow { samples: 20; color: "#00ffff"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: plasmaCanvas; property: "power"; from: 0; to: 1; duration: 1000; easing.type: Easing.OutExpo }
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 300 }
                PauseAnimation { duration: 3000 }
                NumberAnimation { target: plasmaCanvas; property: "power"; to: 0; duration: 500 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 11. TERMINAL (终端指令) - REFACTORED
    // ========================================================================
    Component {
        id: compTerminal
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "black"; radius: width/2; border.color: "#00ff00"; border.width: 2 }
            
            // Matrix Rain Background
            Canvas {
                id: matrixCanvas
                anchors.fill: parent
                
                // Store columns state
                property var columns: []
                
                function initColumns() {
                    columns = []
                    var colCount = width / 15
                    for(var i=0; i<colCount; i++) {
                        columns.push({
                            y: Math.random() * height,
                            speed: 5 + Math.random() * 5,
                            chars: []
                        })
                    }
                }

                Component.onCompleted: initColumns()

                Timer {
                    interval: 50; running: true; repeat: true
                    onTriggered: matrixCanvas.requestPaint()
                }
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.fillStyle = "rgba(0, 0, 0, 0.2)"; 
                    ctx.fillRect(0, 0, width, height);
                    
                    ctx.fillStyle = "#00ff00";
                    ctx.font = "bold 14px Consolas";
                    
                    if(columns.length === 0) initColumns();
                    
                    for(var i=0; i<columns.length; i++) {
                        var col = columns[i];
                        var matrixChar = String.fromCharCode(0x30A0 + Math.random() * 96); 
                        ctx.fillText(matrixChar, i * 15, col.y);
                        
                        col.y += col.speed;
                        if(col.y > height && Math.random() > 0.95) {
                            col.y = 0;
                        }
                    }
                }
            }

            // Typing Effect Text
            Text {
                id: cmdText
                anchors.centerIn: parent
                text: root.hourText
                color: "#00ff00"
                font.family: "Consolas"
                font.pixelSize: parent.width * 0.6
                font.bold: true
                style: Text.Outline; styleColor: "#003300"
                opacity: 0
                z: 10 
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "#00ff00"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                ScriptAction { script: cmdText.text = root.hourText } 
                
                // Fade in
                NumberAnimation { 
                    target: cmdText
                    property: "opacity"
                    from: 0; to: 1
                    duration: 200 
                }
                
                // Decoding simulation
                SequentialAnimation {
                    loops: 5 
                    ScriptAction { script: cmdText.text = Math.floor(Math.random() * 99).toString() }
                    PauseAnimation { duration: 80 }
                }
                
                ScriptAction { script: cmdText.text = root.hourText } 
                
                // Blink cursor effect
                SequentialAnimation {
                    loops: 3
                    PropertyAction { target: cmdText; property: "visible"; value: false }
                    PauseAnimation { duration: 100 }
                    PropertyAction { target: cmdText; property: "visible"; value: true }
                    PauseAnimation { duration: 200 }
                }

                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 12. QUANTUM CORE (量子核心) - REPLACED SOLAR ECLIPSE
    // ========================================================================
    Component {
        id: compQuantum
        Item {
            anchors.fill: parent
            function start() { 
                quantumCanvas.t = 0
                anim.restart() 
            }
            Rectangle { anchors.fill: parent; color: "#050010"; radius: width/2 } // Void Purple
            
            Canvas {
                id: quantumCanvas
                anchors.fill: parent
                property real t: 0
                onTChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    var r = width/2.5;
                    
                    ctx.globalCompositeOperation = "lighter";
                    
                    // 1. Quantum Rings (Rotating on 3 axes)
                    var axes = [
                        {x: 1, y: 0.2, z: 0, speed: 1, color: "#00ffff"},
                        {x: 0.2, y: 1, z: 0.2, speed: 1.5, color: "#ff00ff"},
                        {x: 0, y: 0.5, z: 1, speed: 2, color: "#0088ff"}
                    ];
                    
                    for(var i=0; i<axes.length; i++) {
                        var axis = axes[i];
                        ctx.save();
                        ctx.translate(cx, cy);
                        
                        // Simulate 3D rotation projection
                        var time = t * axis.speed;
                        ctx.rotate(time);
                        ctx.scale(1, 0.3 + 0.2 * Math.sin(time * 0.5)); // Perspective skew
                        
                        ctx.beginPath();
                        ctx.arc(0, 0, r * (0.8 + i*0.1), 0, Math.PI*2);
                        ctx.strokeStyle = axis.color;
                        ctx.lineWidth = 3;
                        ctx.shadowColor = axis.color;
                        ctx.shadowBlur = 10;
                        ctx.stroke();
                        
                        // Electron
                        var ex = r * (0.8 + i*0.1) * Math.cos(time * 3);
                        var ey = r * (0.8 + i*0.1) * Math.sin(time * 3);
                        ctx.fillStyle = "white";
                        ctx.beginPath(); ctx.arc(ex, ey, 4, 0, Math.PI*2); ctx.fill();
                        
                        ctx.restore();
                    }
                    
                    // 2. Core Energy
                    var coreGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, Math.max(0.1, r*0.5));
                    coreGrad.addColorStop(0, "white");
                    coreGrad.addColorStop(0.4, "rgba(0, 255, 255, 0.5)");
                    coreGrad.addColorStop(1, "transparent");
                    ctx.fillStyle = coreGrad;
                    ctx.beginPath(); ctx.arc(cx, cy, r*0.5, 0, Math.PI*2); ctx.fill();
                }
            }
            
            Timer {
                interval: 40; running: true; repeat: true
                onTriggered: quantumCanvas.t += 0.05
            }

            // Failsafe Timer
            Timer {
                interval: 5000; running: true; repeat: false
                onTriggered: root.finishEffect()
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                color: "white"; font.pixelSize: parent.width * 0.6; font.bold: true
                font.family: "Verdana"
                style: Text.Outline; styleColor: "#0044aa"
                opacity: 0; scale: 2
                layer.enabled: true
                layer.effect: Glow { samples: 20; color: "#00ffff"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                ParallelAnimation {
                    NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 200 }
                    NumberAnimation { target: txt; property: "scale"; to: 1; duration: 400; easing.type: Easing.OutBack }
                }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // ========================================================================
    // 13. NEON SYNTHWAVE (霓虹视界) - REPLACED AUDIO VIZ
    // ========================================================================
    Component {
        id: compAudioViz
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#050010"; radius: width/2 } // Deep Void

            Canvas {
                id: vizCanvas
                anchors.fill: parent
                property real t: 0
                onTChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    
                    // 1. Retro Sun (Gradient)
                    var grad = ctx.createLinearGradient(0, cy-height*0.2, 0, cy+height*0.2);
                    grad.addColorStop(0, "#ffcc00");
                    grad.addColorStop(0.5, "#ff00cc");
                    grad.addColorStop(1, "#5500aa");
                    ctx.fillStyle = grad;
                    ctx.beginPath();
                    ctx.arc(cx, cy, width*0.35, Math.PI, 0); // Upper half
                    ctx.fill();
                    
                    // Sun Stripes (Cutout)
                    ctx.fillStyle = "#050010";
                    for(var i=0; i<6; i++) {
                        var y = cy - 5 - i*12;
                        var h = 3 + i; 
                        ctx.fillRect(cx - width*0.4, y, width*0.8, h);
                    }
                    
                    // 2. Perspective Grid (Floor)
                    ctx.strokeStyle = "#00ffff";
                    ctx.lineWidth = 2;
                    ctx.shadowBlur = 10; ctx.shadowColor = "#00ffff";
                    ctx.beginPath();
                    
                    // Radiating lines (Perspective)
                    for(var i=-10; i<=10; i++) {
                        var angle = Math.PI/2 + i * 0.12;
                        var r1 = 30;
                        var r2 = width;
                        ctx.moveTo(cx + r1 * Math.cos(angle), cy + r1 * Math.sin(angle));
                        ctx.lineTo(cx + r2 * Math.cos(angle), cy + r2 * Math.sin(angle));
                    }
                    
                    // Moving Horizontal lines
                    var offset = (t * 80) % 40;
                    for(var j=0; j<8; j++) {
                        var yGrid = cy + 20 + j * 30 + offset;
                        if(yGrid < height) {
                             ctx.moveTo(0, yGrid);
                             ctx.lineTo(width, yGrid);
                        }
                    }
                    ctx.stroke();
                }
            }
            
            Timer {
                interval: 50; running: true; repeat: true
                onTriggered: vizCanvas.t += 0.05
            }
            
            // Failsafe Timer
            Timer { interval: 5000; running: true; repeat: false; onTriggered: root.finishEffect() }

            Text {
                id: txt
                anchors.centerIn: parent
                text: root.hourText
                font.pixelSize: parent.width * 0.6
                font.bold: true
                font.family: "Impact"
                color: "#00ffff"
                style: Text.Outline; styleColor: "#ff00ff"
                layer.enabled: true
                layer.effect: Glow { samples: 20; color: "#00ffff"; transparentBorder: true }
                
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    PropertyAnimation { to: 1.05; duration: 800; easing.type: Easing.InOutSine }
                    PropertyAnimation { to: 0.95; duration: 800; easing.type: Easing.InOutSine }
                }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: txt; property: "opacity"; from: 0; to: 1; duration: 500 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 14. VORTEX (时空漩涡)
    // ========================================================================
    Component {
        id: compVortex
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            
            Canvas {
                id: spiralCanvas
                anchors.fill: parent
                rotation: 0
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    // Gradient Spiral
                    var grad = ctx.createLinearGradient(0,0, width, height);
                    grad.addColorStop(0, "#aa00ff");
                    grad.addColorStop(1, "#00aaff");
                    
                    ctx.strokeStyle = grad;
                    ctx.lineWidth = 4;
                    ctx.shadowBlur = 10; ctx.shadowColor = "#aa00ff";
                    
                    var cx = width/2, cy = height/2;
                    ctx.beginPath();
                    for(var i=0; i<150; i++) {
                        var angle = 0.3 * i;
                        var r = 1 + angle * 0.8;
                        var x = cx + r * Math.cos(angle);
                        var y = cy + r * Math.sin(angle);
                        ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }
            }
            NumberAnimation { target: spiralCanvas; property: "rotation"; from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: true }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText; 
                font.pixelSize: parent.width * 0.6; font.bold: true; font.family: "Times New Roman"
                color: "white"; style: Text.Outline; styleColor: "#aa00ff"
                scale: 0
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "white"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: txt; property: "scale"; to: 1; duration: 1000; easing.type: Easing.OutElastic }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 15. APERTURE (机械光圈)
    // ========================================================================
    Component {
        id: compIris
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#222"; radius: width/2; border.color: "#555"; border.width: 2 }
            
            Item {
                anchors.fill: parent
                Repeater {
                    model: 6
                    Rectangle {
                        width: parent.width/2; height: parent.height/2
                        color: "#333"; border.color: "#00aaff"; border.width: 1
                        transformOrigin: Item.BottomRight
                        x: parent.width/2 - width; y: parent.height/2 - height
                        transform: Rotation { origin.x: width; origin.y: height; angle: index * 60 + openAnim.angle }
                    }
                }
            }
            QtObject { id: openAnim; property real angle: 0 }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                color: "#00aaff"; font.pixelSize: parent.width * 0.65; font.bold: true
                opacity: 0; style: Text.Outline; styleColor: "black"
                layer.enabled: true
                layer.effect: Glow { samples: 15; color: "#00aaff"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: openAnim; property: "angle"; to: 45; duration: 500 }
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 200 }
                PauseAnimation { duration: 3000 }
                NumberAnimation { target: openAnim; property: "angle"; to: 0; duration: 500 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 16. CYBER DATA CORRUPTION (数据崩坏) - REPLACED GLITCH
    // ========================================================================
    Component {
        id: compGlitch
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "black" }
            
            // 1. Chaotic Background Code
            Canvas {
                id: bgCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    ctx.fillStyle = "rgba(0, 255, 50, 0.15)";
                    ctx.font = "bold 12px monospace";
                    for(var i=0; i<30; i++) {
                        var txt = Math.random().toString(16).substring(2);
                        ctx.fillText(txt, Math.random()*width, Math.random()*height);
                    }
                    // Random red blocks
                    if(Math.random() > 0.7) {
                        ctx.fillStyle = "rgba(255, 0, 0, 0.3)";
                        ctx.fillRect(Math.random()*width, Math.random()*height, 100, 20);
                    }
                }
            }

            // 2. RGB Split & Slice Effect for Text
            Item {
                id: textContainer
                anchors.centerIn: parent
                width: parent.width; height: parent.height
                
                Repeater {
                    model: 3
                    Text {
                        anchors.centerIn: parent
                        text: root.hourText
                        font.pixelSize: parent.width * 0.75
                        font.bold: true
                        font.family: "Arial Black"
                        color: ["#ff0000", "#00ff00", "#0000ff"][index]
                        opacity: 0.9
                        style: Text.Outline; styleColor: "black"
                        
                        // Chaotic transform
                        transform: Translate {
                            x: (Math.random()-0.5) * 15 * (glitchTimer.trigger ? 1 : 0)
                            y: (Math.random()-0.5) * 5 * (glitchTimer.trigger ? 1 : 0)
                        }
                        visible: glitchTimer.trigger
                    }
                }
                
                // Main White Text (Flickering)
                Text {
                    anchors.centerIn: parent
                    text: root.hourText
                    font.pixelSize: parent.width * 0.75
                    font.bold: true
                    font.family: "Arial Black"
                    color: "white"
                    visible: !glitchTimer.trigger || Math.random() > 0.5
                }
            }
            
            // 3. "SYSTEM FAILURE" Warning
            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 50
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SYSTEM FAILURE // REBOOTING..."
                font.pixelSize: 14; font.family: "Courier New"; font.bold: true
                color: "red"
                visible: glitchTimer.trigger
            }

            Timer {
                id: glitchTimer
                property bool trigger: false
                interval: 80; running: true; repeat: true
                onTriggered: {
                    trigger = Math.random() > 0.3
                    bgCanvas.requestPaint()
                }
            }
            
            // Failsafe
            Timer { interval: 5000; running: true; repeat: false; onTriggered: root.finishEffect() }

            SequentialAnimation {
                id: anim
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 17. VOXEL RECONSTRUCTION (体素重构) - 3D ASSEMBLY
    // ========================================================================
    Component {
        id: compVoxel
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            
            // 3D Voxel Canvas
            Canvas {
                id: voxelCanvas
                anchors.fill: parent
                property real progress: 0
                onProgressChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    
                    var cx = width/2, cy = height/2;
                    var size = width/5; // Voxel size
                    
                    // Define a 3x5 grid for numbers (simplified)
                    // Just draw a cluster of cubes assembling
                    
                    var cubes = [];
                    // Generate a 3x3x3 cube cluster
                    for(var x=-1; x<=1; x++) {
                        for(var y=-1; y<=1; y++) {
                            for(var z=-1; z<=1; z++) {
                                if (Math.abs(x)+Math.abs(y)+Math.abs(z) > 1) continue; // Sparse
                                cubes.push({x:x, y:y, z:z});
                            }
                        }
                    }
                    
                    // Sort by Z for painter's algorithm
                    cubes.sort(function(a,b){ return b.z - a.z });
                    
                    ctx.lineWidth = 1;
                    ctx.lineJoin = "round";
                    
                    for(var i=0; i<cubes.length; i++) {
                        var cube = cubes[i];
                        
                        // Fly in effect
                        var flyDist = (1.0 - progress) * 200;
                        var fx = cube.x * size + (cube.x * flyDist);
                        var fy = cube.y * size + (cube.y * flyDist);
                        var fz = cube.z * size + (cube.z * flyDist) + (1.0-progress)*500;
                        
                        // Project
                        var scale = 400 / (400 + fz);
                        var px = cx + fx * scale;
                        var py = cy + fy * scale;
                        var pSize = size * scale * 0.45; // slightly smaller to see gaps
                        
                        if (scale <= 0) continue;
                        
                        // Draw Cube Faces
                        // Top
                        ctx.fillStyle = "#00ffaa";
                        ctx.beginPath();
                        ctx.moveTo(px - pSize, py - pSize);
                        ctx.lineTo(px + pSize, py - pSize);
                        ctx.lineTo(px + pSize, py + pSize);
                        ctx.lineTo(px - pSize, py + pSize);
                        ctx.fill();
                        
                        // Side
                        ctx.fillStyle = "#00cc88";
                        ctx.beginPath();
                        ctx.moveTo(px + pSize, py - pSize);
                        ctx.lineTo(px + pSize + pSize*0.5, py - pSize - pSize*0.5);
                        ctx.lineTo(px + pSize + pSize*0.5, py + pSize - pSize*0.5);
                        ctx.lineTo(px + pSize, py + pSize);
                        ctx.fill();
                        
                        // Top (Perspective)
                        ctx.fillStyle = "#ccffee";
                        ctx.beginPath();
                        ctx.moveTo(px - pSize, py - pSize);
                        ctx.lineTo(px + pSize, py - pSize);
                        ctx.lineTo(px + pSize + pSize*0.5, py - pSize - pSize*0.5);
                        ctx.lineTo(px - pSize + pSize*0.5, py - pSize - pSize*0.5);
                        ctx.fill();
                    }
                }
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                color: "white"; font.pixelSize: parent.width * 0.65; font.bold: true
                style: Text.Outline; styleColor: "#003322"
                opacity: 0
                z: 10
                layer.enabled: true
                layer.effect: Glow { samples: 15; color: "#00ffaa"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: voxelCanvas; property: "progress"; from: 0; to: 1; duration: 800; easing.type: Easing.OutBack }
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 300 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 18. DEPTH SONAR (深海声呐) - TACTICAL
    // ========================================================================
    Component {
        id: compSonar
        Item {
            anchors.fill: parent
            function start() { 
                sonarCanvas.angle = 0
                anim.restart() 
            }
            Rectangle { anchors.fill: parent; color: "#001005"; radius: width/2 }
            
            Canvas {
                id: sonarCanvas
                anchors.fill: parent
                property real angle: 0
                property var points: []
                
                function initPoints() {
                    points = [];
                    for(var i=0; i<20; i++) {
                        var a = Math.random() * Math.PI * 2;
                        var dist = (width/2) * (0.3 + 0.6 * Math.random());
                        points.push({a: a, r: dist, alpha: 0});
                    }
                }
                
                Component.onCompleted: initPoints()
                onAngleChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    var maxR = width/2;
                    
                    // Grid Rings
                    ctx.strokeStyle = "rgba(0, 255, 100, 0.3)";
                    ctx.lineWidth = 1;
                    for(var i=1; i<=3; i++) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, maxR * i/3, 0, Math.PI*2);
                        ctx.stroke();
                    }
                    
                    // Crosshair
                    ctx.beginPath();
                    ctx.moveTo(cx, cy-maxR); ctx.lineTo(cx, cy+maxR);
                    ctx.moveTo(cx-maxR, cy); ctx.lineTo(cx+maxR, cy);
                    ctx.stroke();
                    
                    // Sweep Line
                    ctx.save();
                    ctx.translate(cx, cy);
                    ctx.rotate(angle);
                    
                    var grad = ctx.createLinearGradient(0, 0, maxR, 0);
                    grad.addColorStop(0, "rgba(0, 255, 100, 1)");
                    grad.addColorStop(1, "rgba(0, 255, 100, 0)");
                    
                    ctx.strokeStyle = grad;
                    ctx.lineWidth = 3;
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(maxR, 0);
                    ctx.stroke();
                    
                    // Sweep Sector (Fade trail)
                    ctx.fillStyle = "rgba(0, 255, 100, 0.1)";
                    ctx.beginPath();
                    ctx.moveTo(0,0);
                    ctx.arc(0, 0, maxR, 0, -0.5, true); // 0.5 rad trail
                    ctx.fill();
                    ctx.restore();
                    
                    // Detected Points
                    if(points.length === 0) initPoints();
                    
                    ctx.fillStyle = "#00ff66";
                    ctx.shadowColor = "#00ff66"; ctx.shadowBlur = 5;
                    
                    var currentAngle = angle % (Math.PI*2);
                    if (currentAngle < 0) currentAngle += Math.PI*2;
                    
                    for(var j=0; j<points.length; j++) {
                        var p = points[j];
                        // Check if sweep passed this point recently
                        // Normalize point angle
                        var pa = p.a;
                        if (pa < 0) pa += Math.PI*2;
                        
                        var diff = currentAngle - pa;
                        if (diff < 0) diff += Math.PI*2;
                        
                        if (diff < 0.2) { // Just passed
                            p.alpha = 1.0;
                        } else {
                            p.alpha *= 0.95; // Fade out
                        }
                        
                        if (p.alpha > 0.01) {
                            ctx.globalAlpha = p.alpha;
                            var px = cx + p.r * Math.cos(p.a);
                            var py = cy + p.r * Math.sin(p.a);
                            ctx.beginPath();
                            ctx.arc(px, py, 3, 0, Math.PI*2);
                            ctx.fill();
                            // Text label simulation
                            ctx.fillRect(px + 5, py, 10, 2);
                        }
                    }
                    ctx.globalAlpha = 1.0;
                    ctx.shadowBlur = 0;
                }
            }
            
            Timer {
                interval: 30; running: true; repeat: true
                onTriggered: sonarCanvas.angle += 0.1
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                color: "#00ff88"; font.pixelSize: parent.width * 0.6; font.bold: true; font.family: "Courier New"
                opacity: 0
                z: 10
                style: Text.Outline; styleColor: "#002010"
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "#00ff88"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 19. NEURAL NETWORK (神经网络)
    // ========================================================================
    Component {
        id: compNeural
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#0a0a2a"; radius: width/2 }
            
            Canvas {
                id: netCanvas
                anchors.fill: parent
                property real progress: 0
                onProgressChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var cx = width/2, cy = height/2;
                    var nodes = [
                        {x:cx-30, y:cy-30}, {x:cx+30, y:cy-30}, 
                        {x:cx, y:cy+40}, {x:cx-40, y:cy+10}, {x:cx+40, y:cy+10}
                    ];
                    
                    ctx.fillStyle = "white";
                    ctx.strokeStyle = "#00aaff";
                    ctx.lineWidth = 2;
                    ctx.shadowBlur = 5; ctx.shadowColor = "cyan";
                    
                    for(var i=0; i<nodes.length; i++) {
                        ctx.beginPath(); ctx.arc(nodes[i].x, nodes[i].y, 4, 0, Math.PI*2); ctx.fill();
                        for(var j=i+1; j<nodes.length; j++) {
                             if(progress > 0.5) {
                                ctx.beginPath(); ctx.moveTo(nodes[i].x, nodes[i].y); ctx.lineTo(nodes[j].x, nodes[j].y); ctx.stroke();
                             }
                        }
                    }
                }
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText; 
                color: "white"; font.pixelSize: parent.width * 0.6; font.bold: true
                opacity: 0; style: Text.Outline; styleColor: "#000033"
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "white"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: netCanvas; property: "progress"; to: 1; duration: 1000 }
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 20. BIOMETRIC SECURITY (生物识别) - REPLACED LASER SCAN
    // ========================================================================
    Component {
        id: compScanner
        Item {
            anchors.fill: parent; clip: true
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#001020" }
            
            // HUD Canvas
            Canvas {
                id: hudCanvas
                anchors.fill: parent
                property real angle: 0
                onAngleChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    
                    ctx.strokeStyle = "#00aaff";
                    ctx.lineWidth = 2;
                    
                    // Rotating Rings
                    ctx.save();
                    ctx.translate(cx, cy);
                    ctx.rotate(angle);
                    
                    // Ring 1 (Dashed)
                    ctx.beginPath();
                    ctx.arc(0, 0, width*0.4, 0, Math.PI*2);
                    ctx.setLineDash([20, 10]);
                    ctx.stroke();
                    
                    // Ring 2 (Counter rotating)
                    ctx.rotate(-angle * 2);
                    ctx.beginPath();
                    ctx.arc(0, 0, width*0.35, 0, Math.PI*2);
                    ctx.setLineDash([5, 5]);
                    ctx.strokeStyle = "rgba(0, 255, 255, 0.5)";
                    ctx.stroke();
                    
                    ctx.restore();
                    
                    // Target Corners
                    var s = width * 0.45;
                    ctx.setLineDash([]);
                    ctx.strokeStyle = "#00ffff";
                    ctx.lineWidth = 3;
                    
                    // TL
                    ctx.beginPath(); ctx.moveTo(cx-s, cy-s+20); ctx.lineTo(cx-s, cy-s); ctx.lineTo(cx-s+20, cy-s); ctx.stroke();
                    // TR
                    ctx.beginPath(); ctx.moveTo(cx+s, cy-s+20); ctx.lineTo(cx+s, cy-s); ctx.lineTo(cx+s-20, cy-s); ctx.stroke();
                    // BL
                    ctx.beginPath(); ctx.moveTo(cx-s, cy+s-20); ctx.lineTo(cx-s, cy+s); ctx.lineTo(cx-s+20, cy+s); ctx.stroke();
                    // BR
                    ctx.beginPath(); ctx.moveTo(cx+s, cy+s-20); ctx.lineTo(cx+s, cy+s); ctx.lineTo(cx+s-20, cy+s); ctx.stroke();
                }
            }
            
            Timer { interval: 50; running: true; repeat: true; onTriggered: hudCanvas.angle += 0.05 }
            
            // Text
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                font.pixelSize: parent.width * 0.6; font.bold: true; color: "#00ffff"
                style: Text.Outline; styleColor: "#0055aa"
                opacity: 0
            }
            
            // Scanning Line
            Rectangle {
                id: scanLine
                width: parent.width; height: 5
                color: "#00ffff"
                y: -10
                opacity: 0.8
                layer.enabled: true
                layer.effect: Glow { samples: 10; color: "#00ffff"; transparentBorder: true }
            }
            
            // Failsafe
            Timer { interval: 5000; running: true; repeat: false; onTriggered: root.finishEffect() }
            
            SequentialAnimation {
                id: anim
                ParallelAnimation {
                    NumberAnimation { target: scanLine; property: "y"; from: 0; to: parent.height; duration: 1500; loops: 2 }
                    SequentialAnimation {
                        PauseAnimation { duration: 500 }
                        NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                    }
                }
                PauseAnimation { duration: 1500 } // Total ~3000ms pause after scan
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 21. PLASMA SHIELD (等离子护盾) - REPLACED FORCEFIELD
    // ========================================================================
    Component {
        id: compForcefield
        Item {
            anchors.fill: parent
            function start() { 
                shieldCanvas.impact = 0
                anim.restart() 
            }
            Rectangle { anchors.fill: parent; color: "#000510"; radius: width/2 }
            
            Canvas {
                id: shieldCanvas
                anchors.fill: parent
                property real impact: 0
                property real phase: 0
                
                onImpactChanged: requestPaint()
                onPhaseChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    var r = width/2 * 0.95;
                    
                    ctx.globalCompositeOperation = "lighter";

                    // 1. Hex Grid Background (Optimized: Lower density & Batching)
                    ctx.save();
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.clip(); 
                    
                    ctx.strokeStyle = "rgba(255, 100, 0, 0.2)";
                    ctx.lineWidth = 1;
                    // Increased hexSize from /10 to /7 for significantly fewer polygons (performance)
                    var hexSize = width / 7; 
                    
                    // Simple Hex Grid
                    var dx = hexSize * 1.5;
                    var dy = hexSize * Math.sqrt(3);
                    
                    ctx.beginPath(); // Batch drawing start
                    // Reduced range to avoid over-drawing off-screen
                    for(var y=-hexSize; y<height+hexSize; y+=dy) {
                        for(var x=-hexSize; x<width+hexSize; x+=dx) {
                            var yOffset = (Math.floor(x/dx)%2) * (dy/2);
                            // Inline drawHex for performance
                            var hx = x;
                            var hy = y + yOffset;
                            var hr = hexSize * 0.9;
                            
                            // Manually unrolled hex loop
                            // 0
                            ctx.moveTo(hx + hr, hy);
                            // 1
                            ctx.lineTo(hx + hr*0.5, hy + hr*0.866);
                            // 2
                            ctx.lineTo(hx - hr*0.5, hy + hr*0.866);
                            // 3
                            ctx.lineTo(hx - hr, hy);
                            // 4
                            ctx.lineTo(hx - hr*0.5, hy - hr*0.866);
                            // 5
                            ctx.lineTo(hx + hr*0.5, hy - hr*0.866);
                            // Close
                            ctx.lineTo(hx + hr, hy);
                        }
                    }
                    ctx.stroke(); // Batch drawing end
                    ctx.restore();

                    // 2. Impact Shockwave
                    if (impact > 0) {
                        var waveR = r * impact;
                        
                        // Main Ring
                        var grad = ctx.createRadialGradient(cx, cy, Math.max(0, waveR-10), cx, cy, Math.max(0.1, waveR+10));
                        grad.addColorStop(0, "transparent");
                        grad.addColorStop(0.5, "rgba(255, 200, 0, " + (1-impact) + ")");
                        grad.addColorStop(1, "transparent");
                        ctx.fillStyle = grad;
                        ctx.beginPath(); ctx.arc(cx, cy, waveR+20, 0, Math.PI*2); ctx.fill();
                        
                        // Hex distortion rings
                        ctx.strokeStyle = "rgba(255, 150, 0, " + (1-impact) + ")";
                        ctx.lineWidth = 3;
                        ctx.beginPath(); ctx.arc(cx, cy, waveR, 0, Math.PI*2); ctx.stroke();
                        
                        // Sparks
                        for(var i=0; i<12; i++) {
                            var angle = i/12 * Math.PI*2 + phase;
                            var sx = cx + waveR * Math.cos(angle);
                            var sy = cy + waveR * Math.sin(angle);
                            ctx.fillStyle = "#ffffaa";
                            ctx.beginPath(); ctx.arc(sx, sy, 3, 0, Math.PI*2); ctx.fill();
                        }
                    }
                    
                    // 3. Shield Border
                    ctx.shadowBlur = 15; ctx.shadowColor = "#ffaa00";
                    ctx.strokeStyle = "rgba(255, 100, 0, 0.6)";
                    ctx.lineWidth = 3;
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke();
                }
                
                function drawHex(ctx, x, y, r) {
                    // Deprecated: Inlined for performance
                }
            }
            
            Timer { interval: 50; running: true; repeat: true; onTriggered: shieldCanvas.phase += 0.1 }
            
            // Failsafe
            Timer { interval: 5000; running: true; repeat: false; onTriggered: root.finishEffect() }

            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText; 
                color: "#ffcc00"; font.pixelSize: parent.width * 0.6; font.bold: true; font.family: "Verdana"
                style: Text.Outline; styleColor: "#aa4400"
                z: 10 // Ensure on top
                scale: 0.5
                opacity: 0
                layer.enabled: true
                layer.effect: Glow { samples: 20; color: "#ffaa00"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                ParallelAnimation {
                     NumberAnimation { target: shieldCanvas; property: "impact"; from: 0; to: 1.5; duration: 1000; easing.type: Easing.OutCirc }
                     NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 200 }
                     NumberAnimation { target: txt; property: "scale"; to: 1; duration: 600; easing.type: Easing.OutBack }
                }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 22. CRYSTAL (水晶生长)
    // ========================================================================
    Component {
        id: compCrystal
        Item {
            anchors.fill: parent
            function start() { 
                crystalCanvas.growth = 0
                crystalCanvas.shine = 0
                anim.restart() 
            }
            Rectangle { anchors.fill: parent; color: "#100020"; radius: width/2 } // Dark purple bg
            
            Canvas {
                id: crystalCanvas
                anchors.fill: parent
                property real growth: 0
                property real shine: 0
                property var crystals: []
                
                onGrowthChanged: requestPaint()
                onShineChanged: requestPaint()
                
                Component.onCompleted: {
                    // Generate random crystal cluster
                    var count = 15;
                    for(var i=0; i<count; i++) {
                        // Spread from -PI (left) to 0 (right), centered at -PI/2 (up)
                        var u = Math.random() + Math.random() - 1; // Approx normal -1 to 1
                        var angle = -Math.PI/2 + u * 1.0; 
                        
                        var len = 0.5 + Math.random() * 0.4; 
                        var w = 0.08 + Math.random() * 0.08;
                        var hue = 0.7 + Math.random() * 0.2; // Purple/Blue range
                        var color = Qt.hsla(hue, 1.0, 0.5, 1.0);
                        
                        crystals.push({ang: angle, len: len, w: w, color: color, shineOffset: Math.random() * 2});
                    }
                    // Sort by length descending (tallest in back)
                    crystals.sort(function(a,b){ return b.len - a.len });
                }
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var cx = width/2, cy = height/2;
                    
                    ctx.lineJoin = "bevel";
                    
                    for(var i=0; i<crystals.length; i++) {
                        var c = crystals[i];
                        var l = (height/2) * c.len * growth;
                        var w = (width/2) * c.w;
                        
                        ctx.save();
                        ctx.translate(cx, cy + height/4); 
                        ctx.rotate(c.ang + Math.PI/2); 
                        
                        // Draw Crystal Facets
                        // Left Facet
                        ctx.beginPath();
                        ctx.moveTo(0, 0);
                        ctx.lineTo(-w, -l * 0.8);
                        ctx.lineTo(0, -l);
                        ctx.closePath();
                        ctx.fillStyle = c.color;
                        ctx.fill();
                        
                        // Right Facet (Darker)
                        ctx.beginPath();
                        ctx.moveTo(0, 0);
                        ctx.lineTo(w, -l * 0.8);
                        ctx.lineTo(0, -l);
                        ctx.closePath();
                        ctx.fillStyle = Qt.darker(c.color, 1.5);
                        ctx.fill();
                        
                        // Front Ridge
                        ctx.beginPath();
                        ctx.moveTo(0, 0);
                        ctx.lineTo(0, -l);
                        ctx.strokeStyle = "rgba(255,255,255,0.5)";
                        ctx.lineWidth = 1;
                        ctx.stroke();

                        // Outline
                        ctx.beginPath();
                        ctx.moveTo(-w, -l * 0.8);
                        ctx.lineTo(0, -l);
                        ctx.lineTo(w, -l * 0.8);
                        ctx.lineTo(0, 0);
                        ctx.closePath();
                        ctx.strokeStyle = "rgba(255,255,255,0.8)";
                        ctx.lineWidth = 1;
                        
                        // Glow based on growth/shine
                        ctx.shadowBlur = 10 + 5 * Math.sin(shine * Math.PI + i); 
                        ctx.shadowColor = c.color;
                        ctx.stroke();
                        
                        // Sparkle at tip
                        var s = (shine + c.shineOffset) % 2;
                        if (growth > 0.8 && s > 0.9 && s < 1.1) {
                             ctx.fillStyle = "rgba(255, 255, 255, " + (1 - Math.abs(s - 1)*10) + ")"; 
                             ctx.beginPath();
                             ctx.arc(0, -l, 2, 0, Math.PI*2);
                             ctx.fill();
                        }
                        
                        ctx.restore();
                    }
                }
            }
            
            // Shine animation
            Timer {
                interval: 50; running: true; repeat: true
                onTriggered: {
                    crystalCanvas.shine += 0.05
                    if(crystalCanvas.shine > 2) crystalCanvas.shine = 0
                }
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText; 
                color: "white"; z: 1; font.pixelSize: parent.width * 0.65; font.bold: true
                style: Text.Outline; styleColor: "#5500aa"
                opacity: 0
                layer.enabled: true
                layer.effect: Glow { samples: 15; color: "#aa00ff"; transparentBorder: true }
            }
            
            SequentialAnimation {
                id: anim
                NumberAnimation { target: crystalCanvas; property: "growth"; from: 0; to: 1; duration: 1000; easing.type: Easing.OutExpo }
                NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 300 }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }

    // ========================================================================
    // 23. NEBULA FLUID (星云流体) - REPLACED LIQUID FUSION
    // ========================================================================
    Component {
        id: compLiquid
        Item {
            anchors.fill: parent
            function start() { anim.restart() }
            Rectangle { anchors.fill: parent; color: "#000010"; radius: width/2 }
            
            Canvas {
                id: fluidCanvas
                anchors.fill: parent
                property real t: 0
                onTChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0,0,width,height);
                    var cx = width/2, cy = height/2;
                    
                    // Deep Space Nebula Effect
                    ctx.globalCompositeOperation = "screen";
                    
                    // 1. Nebula Clouds (Moving Gradients)
                    var clouds = [
                        { c: "rgba(80, 0, 180, 0.4)", r: 0.6, s: 0.4, o: 0 },
                        { c: "rgba(0, 100, 220, 0.4)", r: 0.8, s: 0.6, o: 2 },
                        { c: "rgba(200, 0, 100, 0.3)", r: 0.7, s: 0.3, o: 4 },
                        { c: "rgba(0, 255, 200, 0.2)", r: 0.9, s: 0.5, o: 6 }
                    ];
                    
                    for(var i=0; i<clouds.length; i++) {
                        var c = clouds[i];
                        var ct = t * c.s;
                        var r = width * 0.5 * c.r + Math.sin(ct + c.o) * 40;
                        var x = cx + Math.cos(ct * 0.7 + c.o) * 60;
                        var y = cy + Math.sin(ct * 0.5 + c.o) * 60;
                        
                        var grad = ctx.createRadialGradient(x, y, 0, x, y, Math.max(0.1, r));
                        grad.addColorStop(0, c.c);
                        grad.addColorStop(1, "transparent");
                        ctx.fillStyle = grad;
                        ctx.beginPath();
                        ctx.arc(x, y, Math.max(0, r), 0, Math.PI*2);
                        ctx.fill();
                    }
                    
                    // 2. Stardust (Twinkling Particles)
                    ctx.globalCompositeOperation = "source-over";
                    ctx.fillStyle = "#ffffff";
                    for(var j=0; j<80; j++) {
                        // Deterministic random positions based on index
                        var sx = (Math.sin(j * 12.9898) * 0.5 + 0.5) * width;
                        var sy = (Math.cos(j * 78.233) * 0.5 + 0.5) * height;
                        
                        // Twinkle effect
                        var twinkle = Math.sin(t * 5 + j) * 0.5 + 0.5;
                        var size = (Math.sin(t * 2 + j) * 1 + 1.5) * twinkle;
                        
                        if(size > 0.1) {
                            ctx.globalAlpha = twinkle;
                            ctx.beginPath();
                            ctx.arc(sx, sy, size, 0, Math.PI*2);
                            ctx.fill();
                        }
                    }
                    ctx.globalAlpha = 1.0;
                }
            }
            
            Timer {
                interval: 40; running: true; repeat: true
                onTriggered: fluidCanvas.t += 0.05
            }
            
            // Failsafe
            Timer {
                interval: 5000; running: true; repeat: false
                onTriggered: root.finishEffect()
            }
            
            Text {
                id: txt
                anchors.centerIn: parent; text: root.hourText
                color: "#ffffff"
                font.pixelSize: parent.width * 0.65
                font.bold: true
                font.family: "Times New Roman"
                font.italic: true
                style: Text.Raised; styleColor: "#000000"
                opacity: 0; scale: 0.8
                layer.enabled: true
                layer.effect: Glow { 
                    samples: 25; 
                    color: "#cc00ff"; 
                    spread: 0.5
                    transparentBorder: true 
                }
            }
            
            SequentialAnimation {
                id: anim
                ParallelAnimation {
                    NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                    NumberAnimation { target: txt; property: "scale"; to: 1; duration: 800; easing.type: Easing.OutElastic }
                }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: root.finishEffect() }
            }
        }
    }
}
