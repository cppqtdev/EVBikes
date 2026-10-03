import QtQuick
import ClusterCore
import ClusterBackend

// Main lamps remain visible in their disabled colour. Extra fault lamps
// appear on demand. A shared square box and gap keep both groups consistent.
Item {
    id: strip

    property bool selfTest: false
    readonly property int iconSize: 32
    readonly property int iconGap: 2

    width: Theme.screenWidth
    height: 64

    Telltale {
        x: 422; y: 20
        size: strip.iconSize
        source: "qrc:/assets/icons/32/tt_left.png"
        blinking: false
        active: strip.selfTest || VehicleData.indicatorLeft || VehicleData.hazard
        activeColor: Theme.telltaleGreen
    }
    Telltale {
        x: 866; y: 20
        size: strip.iconSize
        source: "qrc:/assets/icons/32/tt_right.png"
        blinking: false
        active: strip.selfTest || VehicleData.indicatorRight || VehicleData.hazard
        activeColor: Theme.telltaleGreen
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 16
        y: 20
        spacing: strip.iconGap
        Telltale {
            size: strip.iconSize
            source: "qrc:/assets/icons/32/tt_high_beam.png"
            active: strip.selfTest || VehicleData.highBeam
            activeColor: Theme.telltaleBlue
        }
        Telltale {
            size: strip.iconSize
            source: "qrc:/assets/icons/32/tt_low_beam.png"
            active: strip.selfTest || VehicleData.lowBeam
            activeColor: Theme.telltaleGreen
        }
        Telltale {
            size: strip.iconSize
            source: "qrc:/assets/icons/32/tt_warning.png"
            active: strip.selfTest || VehicleData.faultCode !== 0 || AlertData.level >= AlertData.LevelWarning
                || VehicleData.driveStale || VehicleData.batteryStale || VehicleData.powertrainStale
            activeColor: AlertData.level === AlertData.LevelCritical || AlertData.popupVisible ? Theme.telltaleRed : Theme.telltaleAmber
        }
        Telltale {
            size: strip.iconSize
            source: "qrc:/assets/icons/32/tt_abs.png"
            active: strip.selfTest || VehicleData.absFault
            activeColor: Theme.telltaleAmber
        }
        Telltale {
            size: strip.iconSize
            source: "qrc:/assets/icons/32/tt_battery.png"
            active: strip.selfTest || VehicleData.batteryPercent <= 15 || VehicleData.chargeState === VehicleData.ChargeFault
                || AlertData.kind === AlertData.BatteryOverheat
            activeColor: VehicleData.batteryPercent <= 5 || AlertData.kind === AlertData.BatteryOverheat ? Theme.telltaleRed : Theme.telltaleAmber
        }
        VehicleWarnings { iconSize: strip.iconSize; spacing: strip.iconGap }
    }
}
