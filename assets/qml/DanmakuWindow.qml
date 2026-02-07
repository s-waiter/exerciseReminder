import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15

Window {
    id: root
    visible: false // Invisible controller, spawns child windows
    // Add TransparentForInput as a fail-safe against invisible blocking
    flags: Qt.FramelessWindowHint | Qt.Tool | Qt.WindowTransparentForInput
    color: "transparent"
    
    // Full screen geometry (used for calculations)
    x: screen ? screen.virtualX : 0
    y: screen ? screen.virtualY : 0
    width: screen ? screen.width : Screen.width
    height: screen ? screen.height : Screen.height
    
    // Properties passed from Main.qml
    property string titleStr: "休息提醒"
    property int type: 0 // 0: Work, 1: Life, 2: Anniversary, 3: Health
    property string messageStr: "该休息一下了"
    property string scheduleId: ""
    property bool forceMode: false
    
    // Signals
    signal snoozeRequested(int minutes)
    signal dismissRequested()
    
    // Theme Color based on Type
    property color themeColor: {
        switch(type) {
            case 0: return "#00d2ff"; // Cyan (Work)
            case 1: return "#00ff88"; // Neon Green (Life)
            case 2: return "#ff0055"; // Neon Pink (Anniversary)
            case 3: return "#ff9500"; // Neon Orange (Health)
            default: return "#00d2ff";
        }
    }
    
    // Escalation Logic
    property int activeCount: 0 // Track active danmaku count manually
    property int escalationLevel: 0
    property int baseSpeed: 10000 // ms to cross screen
    property int spawnInterval: 3000 // Increased from 2000 to reduce load
    
    // Object Pool
    property var danmakuPool: []
    property int maxPoolSize: 15 // Limit pool size
    
    // Effect Overlay (Singleton-like, one per DanmakuWindow/Screen)
    // This window stays alive to play effects
    property var effectOverlay: null

    Component.onCompleted: {
        spawnTimer.start()
        escalationTimer.start()
        
        // Create the effect overlay for this screen
        var component = Qt.createComponent("DanmakuEffectOverlay.qml");
        if (component.status === Component.Ready) {
            effectOverlay = component.createObject(root, {
                "targetX": Qt.binding(function(){ return root.x }),
                "targetY": Qt.binding(function(){ return root.y }),
                "targetWidth": Qt.binding(function(){ return root.width }),
                "targetHeight": Qt.binding(function(){ return root.height })
            });
        } else {
            console.log("Error loading DanmakuEffectOverlay:", component.errorString());
        }
    }
    
    Component.onDestruction: {
        // Cleanup pool
        for (var i = 0; i < danmakuPool.length; i++) {
            if (danmakuPool[i]) danmakuPool[i].destroy();
        }
        // Overlay is child of root, will be destroyed automatically
    }
    
    function closeWindow() {
        // Destroying the root window will destroy all child windows (DanmakuItems and Overlay)
        root.destroy()
    }
    
    // Timer to escalate urgency
    Timer {
        id: escalationTimer
        interval: 30000 // Every 30s
        repeat: true
        onTriggered: {
            if (root.escalationLevel < 5) {
                root.escalationLevel++
                // Speed up spawn
                if (spawnInterval > 500) spawnInterval -= 300
            }
        }
    }
    
    // Dynamic Danmaku Spawner
    Timer {
        id: spawnTimer
        interval: spawnInterval
        repeat: true
        onTriggered: {
            createOrReuseDanmaku();
        }
    }
    
    function createOrReuseDanmaku() {
        // Limit concurrent danmaku to avoid overload
        if (activeCount > 10) return; 

        var randomY = root.y + Math.random() * (root.height - 100) + 50; // Screen Y coordinates
        var randomSpeed = baseSpeed * (0.8 + Math.random() * 0.4) - (escalationLevel * 500); // Faster over time
        if (randomSpeed < 2000) randomSpeed = 2000;
        
        var fontSize = 24 + (escalationLevel * 2) + Math.random() * 10;
        var txt = titleStr;
        
        var item = null;
        
        // Try to reuse from pool
        if (danmakuPool.length > 0) {
            item = danmakuPool.pop();
            if (item) {
                activeCount++;
                item.restart(txt, randomY, randomSpeed, themeColor, fontSize, root.x, root.width);
                return;
            }
        }
        
        // Create new if pool is empty
        var component = Qt.createComponent("DanmakuItem.qml");
        if (component.status === Component.Ready) {
            item = component.createObject(root, {
                "text": txt,
                "yPos": randomY,
                "duration": randomSpeed,
                "textColor": themeColor,
                "fontSize": fontSize,
                "screenX": root.x,
                "screenWidth": root.width
            });
            
            if (item) {
                activeCount++;
                setupItemConnections(item);
            }
        } else {
            console.log("Error loading DanmakuItem:", component.errorString());
        }
    }
    
    function setupItemConnections(item) {
        // Handle recycle request (clicked or watchdog)
        item.requestRecycle.connect(function() {
            recycleItem(item);
        });
        
        // Handle natural finish
        item.finished.connect(function() {
            recycleItem(item);
        });
        
        // Handle effect request
        item.requestEffect.connect(function(gx, gy, c) {
            if (effectOverlay) {
                effectOverlay.playSliceEffect(gx, gy, c);
            }
        });
    }
    
    function recycleItem(item) {
        if (!item) return;
        
        // Defensive: Check if already in pool to prevent duplicates
        // This is critical for object pool integrity
        for (var i = 0; i < danmakuPool.length; i++) {
            if (danmakuPool[i] === item) {
                // Already in pool, do nothing
                return;
            }
        }
        
        if (activeCount > 0) activeCount--;
        
        // Reset item state just in case
        item.visible = false;
        
        // Add to pool if not full
        if (danmakuPool.length < maxPoolSize) {
            danmakuPool.push(item);
        } else {
            // Pool full, destroy extra items to free memory
            item.destroy();
        }
    }
}
