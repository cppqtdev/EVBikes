import QtQuick
import ClusterCore
import ClusterBackend

// "57 KPH" with a light top and a mint lower part (two clipped copies).
Item {
    id: speed

    property int value: VehicleData.speedKmh
    property string unit: "KPH"

    width: 460
    height: 200

    Text {
        id: base
        x: 0
        y: 0
        width: 390
        horizontalAlignment: Text.AlignRight
        text: "" + speed.value
        color: Theme.digitGrey
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSpeed
        font.bold: true
        font.italic: true
    }

    Item {
        x: 0
        y: 0
        width: 420
        height: 72
        clip: true

        Text {
            width: 390
            horizontalAlignment: Text.AlignRight
            text: base.text
            color: "#F1F3F3"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSpeed
            font.bold: true
            font.italic: true
        }
    }

    Item {
        x: 0
        y: 104
        width: 420
        height: 12
        clip: true

        Text {
            y: -104
            width: 390
            horizontalAlignment: Text.AlignRight
            text: base.text
            color: "#C2DED6"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSpeed
            font.bold: true
            font.italic: true
        }
    }

    Item {
        x: 0
        y: 116
        width: 420
        height: 60
        clip: true

        Text {
            y: -116
            width: 390
            horizontalAlignment: Text.AlignRight
            text: base.text
            color: Theme.sport || Theme.alertMode ? "#E7B3A6" : Theme.digitShade
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
        color: Theme.sport || Theme.alertMode ? "#F0C2B5" : "#B6F2E0"
        font.family: Theme.fontFamily
        font.pixelSize: 20
        font.bold: true
        font.italic: true
    }
}
