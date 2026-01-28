import QtQuick 2.15

QtObject {
    id: themeController

    // 当前激活的主题状态
    property var currentTheme: {
        "gradientStart": "#134E5E",
        "gradientEnd": "#71B280",
        "accentColor": "#ffffff",
        "textColor": "#134E5E",
        "icon": "🏃",
        "particleShape": "circle",
        "centerVisual": "circle_ring",
        "quote": "身体是革命的本钱，起来充充电吧 ⚡" // Added quote to theme object
    }

    // 预设调色板库
    readonly property var colorPalettes: [
        { s: "#134E5E", e: "#71B280", t: "#134E5E" },
        { s: "#2b5876", e: "#4e4376", t: "#2b5876" },
        { s: "#ff512f", e: "#dd2476", t: "#dd2476" },
        { s: "#000000", e: "#434343", t: "#434343" },
        { s: "#1A2980", e: "#26D0CE", t: "#1A2980" },
        { s: "#CC95C0", e: "#19547b", t: "#19547b" },
        { s: "#EB3349", e: "#F45C43", t: "#EB3349" },
        { s: "#4CA1AF", e: "#C4E0E5", t: "#4CA1AF" },
        { s: "#8360c3", e: "#2ebf91", t: "#8360c3" },
        { s: "#00bf8f", e: "#001510", t: "#00bf8f" }
    ]

    readonly property var icons: ["🏃", "🧘", "🤸", "🏋️", "🚶", "🕺", "💃", "🧗", "🚴", "🏊"]
    readonly property var particleShapes: ["circle", "square", "line"]
    readonly property var centerVisuals: ["circle_ring", "tech_hexagon", "radar_scan", "energy_pulse"]
    readonly property var quotes: [
        "身体是革命的本钱，起来充充电吧 ⚡",
        "久坐伤身，动动更健康 🏃",
        "喝口水，伸个懒腰，精神百倍 💪",
        "现在的休息，是为了更好的出发 🚀",
        "保护脊椎，人人有责 🦴",
        "在这个Bug改完之前，先改改你的坐姿 🧘",
        "代码可以重构，身体只有一个 ❤️",
        "离开椅子，你的灵感才会回来 💡",
        "颈椎在哭泣，快去救救它 🚑",
        "动起来，让多巴胺飞一会儿 🧠"
    ]

    function generateRandomTheme() {
        var pal = colorPalettes[Math.floor(Math.random() * colorPalettes.length)];
        var icn = icons[Math.floor(Math.random() * icons.length)];
        var pShape = particleShapes[Math.floor(Math.random() * particleShapes.length)];
        var cVis = centerVisuals[Math.floor(Math.random() * centerVisuals.length)];
        var qt = quotes[Math.floor(Math.random() * quotes.length)];

        currentTheme = {
            "gradientStart": pal.s,
            "gradientEnd": pal.e,
            "accentColor": "#ffffff",
            "textColor": pal.t,
            "icon": icn,
            "particleShape": pShape,
            "centerVisual": cVis,
            "quote": qt
        };
    }
}
