pragma Singleton
import QtQuick

// Qt Quick fallback does not expose QUL's renderer profiler. Explicitly mark
// unavailable values instead of substituting a timer-derived fake FPS.
QtObject {
    readonly property bool enabled: false
    property bool recording: false
    readonly property real fps: 0
    readonly property real repaint: 0
    readonly property real currentCpuLoad: 0
}
