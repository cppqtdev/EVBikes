import QtQuick
import ClusterCore

// Follows a fast-changing integer at a rate a person can read.
//
// The simulator moves speed by up to 1.2 km/h a tick, so a readout bound
// straight to it re-renders many times a second and reads as flicker rather
// than as a number. This closes a share of the remaining gap on every tick,
// with a floor of one, so the reading eases instead of snapping.
//
// The defaults were picked by simulating a 12 km/h per second climb, which is
// what a bike actually does: five updates a second, never more than three
// km/h at a time, settling two behind. That is the cadence a real cluster
// runs its digital speed at. Under the simulator's much harsher sport ramp it
// falls back to three updates a second in larger steps, which is honest -
// the speed really is changing that fast.
Item {
    id: damped

    property int source: 0
    property int value: 0
    property int tickMs: 200
    property real fraction: 0.6

    width: 0
    height: 0

    Timer {
        interval: damped.tickMs
        repeat: true
        running: true

        onTriggered: {
            var gap = damped.source - damped.value
            if (gap === 0)
                return
            var step = Math.max(1, Math.round(Math.abs(gap) * damped.fraction))
            damped.value = gap > 0 ? damped.value + step : damped.value - step
        }
    }
}
