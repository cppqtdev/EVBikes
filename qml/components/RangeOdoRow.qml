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

    NumberReadout {
        id: rangeValue
        x: 525
        y: 1
        value: Format.distanceValueKm(VehicleData.rangeKm)
        stale: VehicleData.batteryStale
        fit: true
        digitSize: 30
        digitFont: Qt.font({ family: Theme.fontFamily, pixelSize: 30, bold: true, italic: true })
        widthFactor: 0.6
    }

    Text {
        x: rangeValue.x + rangeValue.width + 5
        y: 15
        text: Format.distanceUnitName()
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

    NumberReadout {
        id: odoValue
        x: 728
        y: 1
        value: Format.distanceValueKm(VehicleData.odometerKm)
        stale: VehicleData.driveStale
        fit: true
        digitSize: 30
        digitFont: Qt.font({ family: Theme.fontFamily, pixelSize: 30, bold: true, italic: true })
        widthFactor: 0.6
        duration: Theme.animSlow
    }

    Text {
        x: odoValue.x + odoValue.width + 5
        y: 15
        text: Format.distanceUnitName()
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
