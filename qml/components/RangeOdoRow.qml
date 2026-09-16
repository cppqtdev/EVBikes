import QtQuick
import ClusterCore
import ClusterBackend

// "RANGE 20 km   ODO 9 km" between two faded lines.
Item {
    id: row

    width: Theme.screenWidth
    height: 60

    FadeLine {
        x: 500
        y: 0
        width: 280
    }

    Text {
        x: 463
        y: 15
        text: qsTr("RANGE")
        color: Theme.labelTeal
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        font.italic: true
    }

    Text {
        id: rangeValue
        x: 525
        y: 1
        text: "" + VehicleData.rangeKm
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 30
        font.bold: true
        font.italic: true
    }

    Text {
        x: rangeValue.x + rangeValue.width + 5
        y: 15
        text: "km"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.italic: true
    }

    Text {
        x: 684
        y: 15
        text: qsTr("ODO")
        color: Theme.labelTeal
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        font.italic: true
    }

    Text {
        id: odoValue
        x: 728
        y: 1
        text: "" + VehicleData.odometerKm
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 30
        font.bold: true
        font.italic: true
    }

    Text {
        x: odoValue.x + odoValue.width + 5
        y: 15
        text: "km"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.italic: true
    }

    FadeLine {
        x: 500
        y: 35
        width: 280
        lineColor: Theme.stroke
    }
}
