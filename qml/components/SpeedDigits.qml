import QtQuick
import ClusterCore
import ClusterBackend

// "57 KPH" as one grey number whose last rows fade to mint over a short band.
Item {
    id: speed

    property int value: VehicleData.speedKmh
    property string unit: "KPH"
    property color bodyColor: Theme.digitGrey
    property color tailColor: Theme.sport || Theme.alertMode ? "#E7B3A6" : Theme.digitShade

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

    width: 460
    height: 200

    Text {
        id: base
        x: 0
        y: 0
        width: 390
        horizontalAlignment: Text.AlignRight
        text: "" + speed.shownValue
        color: speed.bodyColor
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
                color: Qt.rgba(speed.bodyColor.r + (speed.tailColor.r - speed.bodyColor.r) * band.mix,
                               speed.bodyColor.g + (speed.tailColor.g - speed.bodyColor.g) * band.mix,
                               speed.bodyColor.b + (speed.tailColor.b - speed.bodyColor.b) * band.mix, 1)
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
            color: speed.tailColor
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
        color: Theme.sport || Theme.alertMode ? "#F0C2B5" : Theme.digitUnit
        font.family: Theme.fontFamily
        font.pixelSize: 20
        font.bold: true
        font.italic: true
    }
}
