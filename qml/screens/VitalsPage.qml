import QtQuick
import ClusterCore
import ClusterBackend

//  The five readings the board's "Motorcycle Status" node asks for. Every one
//  of them already arrived in VehicleData and was drawn only inside an alert,
//  a bar or a corner of the riding screen; this is the page that lists them.
//
//  "Bike status" is taken by the ride summary, so this one is Vitals.
//
//  Stale guards follow the node each reading comes from: range and pack
//  temperature are BMS, so batteryStale; power is VCU and motor, so
//  driveStale. Tyre pressure is the TPMS node and the fault code is the fault
//  node, and neither has a stale flag, so both are shown as they are -- the
//  same thing TyreAlertOverlay already does.
PageBase {
    id: page

    pageId: Router.menuVitals

    readonly property string dash: "- -"

    Text {
        x: 400
        y: 86
        text: qsTr("TYRE")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 740
        y: 86
        text: qsTr("BATTERY")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Rectangle {
        x: 400
        y: 108
        width: 480
        height: 1
        color: "#3E3E3E"
    }

    // ---- left column ------------------------------------------------------

    Text {
        x: 400
        y: 120
        text: qsTr("Front")
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 400
        y: 142
        text: Format.tenths(VehicleData.tyreFrontPsiX10) + qsTr(" psi")
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 22
    }

    Text {
        x: 400
        y: 180
        text: qsTr("Rear")
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 400
        y: 202
        text: Format.tenths(VehicleData.tyreRearPsiX10) + qsTr(" psi")
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 22
    }

    Text {
        x: 400
        y: 240
        text: qsTr("Power")
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 400
        y: 262
        text: VehicleData.driveStale ? page.dash : VehicleData.powerPercent + " %"
        color: VehicleData.driveStale ? Theme.textMuted : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 22
    }

    // ---- right column -----------------------------------------------------

    Text {
        x: 740
        y: 120
        text: qsTr("Range")
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 740
        y: 142
        text: VehicleData.batteryStale ? page.dash
            : Format.distanceValueKm(VehicleData.rangeKm) + " " + Format.distanceUnitName()
        color: VehicleData.batteryStale ? Theme.textMuted : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 22
    }

    Text {
        x: 740
        y: 180
        text: qsTr("Pack temperature")
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 740
        y: 202
        text: VehicleData.batteryStale ? page.dash : VehicleData.packTempC + " °C"
        color: VehicleData.batteryStale ? Theme.textMuted : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 22
    }

    Text {
        x: 740
        y: 240
        text: qsTr("Errors")
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 740
        y: 262
        text: VehicleData.faultCode === 0 ? qsTr("None") : qsTr("Code ") + VehicleData.faultCode
        color: VehicleData.faultCode === 0 ? Theme.textPrimary : Theme.red
        font.family: Theme.fontFamily
        font.pixelSize: 22
    }
}
