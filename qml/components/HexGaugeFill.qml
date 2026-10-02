import QtQuick
import QtQuick.Shapes
import ClusterCore

// Five bounded quadrilaterals form a continuous fill along the hex rim.
// Only vertex positions change; no images or delegates are allocated per tick.
Item {
    id: fill
    property real angle: 160.2
    property color color: Theme.teal
    width: 420
    height: 290
    function progress(start: real, end: real, ax: real, ay: real, bx: real, by: real) : real {
        if (angle <= start) return 0
        if (angle >= end) return 1
        var dx = Math.cos(angle * Math.PI / 180)
        var dy = Math.sin(angle * Math.PI / 180)
        return Math.max(0, Math.min(1, ((205 - ax) * dy - (138.5 - ay) * dx) / ((bx - ax) * dy - (by - ay) * dx)))
    }
    Shape {
        id: side0
        width: 420; height: 290
        readonly property real amount: fill.progress(125.863, 180.000, 115, 263, 27, 138.5)
        visible: amount > 0
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: fill.color
            startX: 115; startY: 263
            PathLine { x: 115 + -88 * side0.amount; y: 263 + -124.5 * side0.amount }
            PathLine { x: 152.564 + -69.233 * side0.amount; y: 236.449 + -97.949 * side0.amount }
            PathLine { x: 152.564; y: 236.449 }
            PathLine { x: 115; y: 263 }
        }
    }
    Shape {
        id: side1
        width: 420; height: 290
        readonly property real amount: fill.progress(180.000, 234.137, 27, 138.5, 115, 14)
        visible: amount > 0
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: fill.color
            startX: 27; startY: 138.5
            PathLine { x: 27 + 88 * side1.amount; y: 138.5 + -124.5 * side1.amount }
            PathLine { x: 83.331 + 61.141 * side1.amount; y: 138.5 + -86.500 * side1.amount }
            PathLine { x: 83.331; y: 138.5 }
            PathLine { x: 27; y: 138.5 }
        }
    }
    Shape {
        id: side2
        width: 420; height: 290
        readonly property real amount: fill.progress(234.137, 305.863, 115, 14, 295, 14)
        visible: amount > 0
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: fill.color
            startX: 115; startY: 14
            PathLine { x: 115 + 180 * side2.amount; y: 14 + 0 * side2.amount }
            PathLine { x: 144.471 + 121.057 * side2.amount; y: 52.000 + -1.421e-14 * side2.amount }
            PathLine { x: 144.471; y: 52.000 }
            PathLine { x: 115; y: 14 }
        }
    }
    Shape {
        id: side3
        width: 420; height: 290
        readonly property real amount: fill.progress(305.863, 360.000, 295, 14, 383, 138.5)
        visible: amount > 0
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: fill.color
            startX: 295; startY: 14
            PathLine { x: 295 + 88 * side3.amount; y: 14 + 124.5 * side3.amount }
            PathLine { x: 265.529 + 61.141 * side3.amount; y: 52.0 + 86.5 * side3.amount }
            PathLine { x: 265.529; y: 52.0 }
            PathLine { x: 295; y: 14 }
        }
    }
    Shape {
        id: side4
        width: 420; height: 290
        readonly property real amount: fill.progress(360.000, 414.137, 383, 138.5, 295, 263)
        visible: amount > 0
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: fill.color
            startX: 383; startY: 138.5
            PathLine { x: 383 + -88 * side4.amount; y: 138.5 + 124.5 * side4.amount }
            PathLine { x: 326.669 + -69.233 * side4.amount; y: 138.5 + 97.949 * side4.amount }
            PathLine { x: 326.669; y: 138.5 }
            PathLine { x: 383; y: 138.5 }
        }
    }
}
