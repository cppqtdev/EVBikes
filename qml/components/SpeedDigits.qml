import QtQuick
import ClusterCore
import ClusterBackend

// "57 KPH" as one grey number whose last rows fade to mint over a short band.
Item {
    id: speed

    property int value: Format.speedValue(VehicleData.speedKmh)
    property string unit: Format.speedUnit()
    property color bodyColor: Theme.digitGrey
    property color tailColor: Theme.sport || Theme.alertMode ? "#E7B3A6" : Theme.digitShade

    // Speed stops arriving when the vehicle control unit goes quiet. The last
    // figure would sit there looking live, so the reading goes to dashes in the
    // muted ink and the warning telltale carries the fault.
    property bool stale: VehicleData.driveStale
    readonly property string shownText: stale ? "--" : "" + shownValue
    readonly property color inkBody: stale ? Theme.textMuted : bodyColor
    readonly property color inkTail: stale ? Theme.textMuted : tailColor

    // The raw speed changes many times a second, which reads as the number
    // flickering. Follow it at a readable rate instead.
    readonly property int shownValue: damper.value

    DampedInt {
        id: damper
        source: speed.value
    }

    // Fade band measured on the reference frames: 18 rows, then a flat tail.
    readonly property int fadeTop: 104
    readonly property int fadeSteps: 6
    readonly property int stepHeight: 3
    readonly property int tailTop: fadeTop + fadeSteps * stepHeight

    // The reference carries a soft footing under the number: measured below the
    // baseline it falls 89, 69, 53, 34, 23, 14 over seven rows, hugging each
    // stem rather than lying in a band. There is no blur on this renderer, so
    // it is three copies of the same glyphs pushed down and faded. Matched to
    // within three levels at every row.
    readonly property int shadowSteps: 3

    width: 460
    height: 200

    Repeater {
        model: speed.shadowSteps

        Text {
            x: 0
            y: 2 + index * 2
            width: 390
            horizontalAlignment: Text.AlignRight
            text: speed.shownText
            color: speed.inkTail
            opacity: index === 0 ? 0.55 : (index === 1 ? 0.30 : 0.10)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSpeed
            font.bold: true
            font.italic: true
        }
    }

    Text {
        id: base
        x: 0
        y: 0
        width: 390
        horizontalAlignment: Text.AlignRight
        text: speed.shownText
        color: speed.inkBody
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSpeed
        font.bold: true
        font.italic: true
    }

    Repeater {
        model: speed.fadeSteps

        Item {
            id: band

            readonly property real mix: (index + 1) / speed.fadeSteps

            x: 0
            y: speed.fadeTop + index * speed.stepHeight
            width: 420
            height: speed.stepHeight
            clip: true

            Text {
                y: -band.y
                width: 390
                horizontalAlignment: Text.AlignRight
                text: base.text
                color: Qt.rgba(speed.inkBody.r + (speed.inkTail.r - speed.inkBody.r) * band.mix,
                               speed.inkBody.g + (speed.inkTail.g - speed.inkBody.g) * band.mix,
                               speed.inkBody.b + (speed.inkTail.b - speed.inkBody.b) * band.mix, 1)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSpeed
                font.bold: true
                font.italic: true
            }
        }
    }

    Item {
        id: tail

        x: 0
        y: speed.tailTop
        width: 420
        height: speed.height - speed.tailTop
        clip: true

        Text {
            y: -tail.y
            width: 390
            horizontalAlignment: Text.AlignRight
            text: base.text
            color: speed.inkTail
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSpeed
            font.bold: true
            font.italic: true
        }
    }

    Text {
        x: 382
        y: 116
        text: speed.unit
        color: speed.stale ? Theme.textMuted
               : (Theme.sport || Theme.alertMode ? "#F0C2B5" : Theme.digitUnit)
        font.family: Theme.fontFamily
        font.pixelSize: 20
        font.bold: true
        font.italic: true
    }
}
