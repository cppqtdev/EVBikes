import QtQuick
import QtQuickUltralite.Extras
import ClusterBackend
import ClusterCore

// QulPerf supplies renderer measurements, not simulator ticks. Reuse the
// existing uptime publication for aggregation; no extra animation/timer.
Item {
    id: perf
    width: 378
    height: 52
    visible: SystemData.showPerformance
    property int sampleIndex: Math.floor(SystemData.uptimeMs / 2000)
    property int samples: 0
    property real minimum: 0
    property real average: 0
    Component.onCompleted: QulPerf.recording = SystemData.showPerformance
    onVisibleChanged: {
        QulPerf.recording = visible
        samples = 0
        minimum = 0
        average = 0
    }
    onSampleIndexChanged: {
        if (visible && QulPerf.enabled && (QulPerf.fps > 0 || samples > 0)) {
            var count = samples + 1
            var mean = average + (QulPerf.fps - average) / count
            var low = samples === 0 ? QulPerf.fps : Math.min(minimum, QulPerf.fps)
            samples = count
            average = mean
            minimum = low
        }
    }
    Text {
        x: 5; y: 1; width: 368; height: 16
        text: !QulPerf.enabled ? "FPS: n/a (QUL profiling unavailable)"
            : samples === 0 ? "FPS: waiting for renderer samples"
            : "FPS " + QulPerf.fps.toFixed(1) + "  min " + perf.minimum.toFixed(1)
              + "  avg " + perf.average.toFixed(1)
        color: "#FFB6C1"
        font.family: Theme.fontFamily; font.pixelSize: 12
    }
    Text {
        x: 5; y: 18; width: 368; height: 16
        text: "Repaint " + (QulPerf.enabled ? QulPerf.repaint.toFixed(1) + "%" : "n/a")
            + "  frame~ " + (QulPerf.fps > 0 ? (1000 / QulPerf.fps).toFixed(1) + "ms" : "n/a")
            + "  CPU " + (SystemData.demoMode || !QulPerf.enabled ? "n/a" : QulPerf.currentCpuLoad.toFixed(0) + "%")
        color: "#FFB6C1"
        font.family: Theme.fontFamily; font.pixelSize: 12
    }
    Text {
        x: 5; y: 35; width: 368; height: 16
        text: "HeapPk " + (SystemData.heapPeakKiB > 0 ? SystemData.heapPeakKiB + "KiB" : "n/a")
            + "  StackPk " + (SystemData.stackPeakKiB > 0 ? SystemData.stackPeakKiB + "KiB" : "n/a")
            + "  [F12]"
        color: "#C3C8CA"
        font.family: Theme.fontFamily; font.pixelSize: 12
    }
}
