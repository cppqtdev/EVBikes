import QtQuick
import ClusterCore
import ClusterBackend

// Three permanent digit cells. Leading hundreds hide without moving tens,
// units or the unit label. Two digits remain visible at speeds below 100.
Item {
    id: speed
    property int value: Math.max(0, Math.min(999, Format.speedValue(VehicleData.speedKmh)))
    property bool stale: VehicleData.driveStale
    width: 460
    height: 200

    Repeater {
        model: 3
        Text {
            x: 160 + index * 78
            y: 0
            width: 78
            height: 166
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: index > 0 || (!speed.stale && speed.value >= 100)
            text: speed.stale ? "-" : Format.digitAt(speed.value, 2 - index)
            color: speed.stale ? Theme.textMuted : Theme.digitGrey
            font.family: Theme.fontFamily
            font.pixelSize: 124
            font.bold: true
            font.italic: true
        }
    }

    Text {
        x: 408
        y: 116
        width: 65
        height: 30
        text: Format.speedUnit()
        color: speed.stale ? Theme.textMuted : Theme.digitUnit
        font.family: Theme.fontFamily
        font.pixelSize: 20
        font.bold: true
        font.italic: true
    }
}
