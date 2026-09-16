import QtQuick
import ClusterCore
import ClusterBackend

// Telltales inside the top housing. They mirror the real lamp / fault state.
Item {
    id: strip

    property bool selfTest: false

    width: Theme.screenWidth
    height: 64

    Telltale {
        x: 430 - width / 2
        y: 32 - height / 2
        size: 32
        source: "qrc:/assets/icons/32/tt_left.png"
        blinking: !strip.selfTest
        on: strip.selfTest || VehicleData.indicatorLeft || VehicleData.hazard
        onColor: Theme.telltaleGreen
    }
    Telltale {
        x: 497 - width / 2
        y: 32 - height / 2
        size: 34
        source: "qrc:/assets/icons/34/tt_high_beam.png"
        on: strip.selfTest || VehicleData.highBeam
        onColor: Theme.telltaleBlue
    }
    Telltale {
        x: 573 - width / 2
        y: 32 - height / 2
        size: 34
        source: "qrc:/assets/icons/34/tt_low_beam.png"
        on: strip.selfTest || VehicleData.lowBeam
        onColor: Theme.telltaleGreen
    }
    Telltale {
        x: 647 - width / 2
        y: 32 - height / 2
        size: 28
        source: "qrc:/assets/icons/28/tt_warning.png"
        on: strip.selfTest || VehicleData.faultCode !== 0 || AlertData.level >= AlertData.LevelWarning
        onColor: AlertData.level === AlertData.LevelCritical || AlertData.popupVisible ? Theme.telltaleRed : Theme.telltaleAmber
    }
    Telltale {
        x: 726 - width / 2
        y: 32 - height / 2
        size: 40
        source: "qrc:/assets/icons/40/tt_abs.png"
        on: strip.selfTest || VehicleData.absFault
        onColor: Theme.telltaleAmber
    }
    Telltale {
        x: 805 - width / 2
        y: 32 - height / 2
        size: 36
        source: "qrc:/assets/icons/36/tt_battery.png"
        on: strip.selfTest || VehicleData.batteryPercent <= 15 || VehicleData.chargeState === VehicleData.ChargeFault
            || AlertData.kind === AlertData.BatteryOverheat
        onColor: VehicleData.batteryPercent <= 5 || AlertData.kind === AlertData.BatteryOverheat ? Theme.telltaleRed : Theme.telltaleAmber
    }
    Telltale {
        x: 881 - width / 2
        y: 32 - height / 2
        size: 32
        source: "qrc:/assets/icons/32/tt_right.png"
        blinking: !strip.selfTest
        on: strip.selfTest || VehicleData.indicatorRight || VehicleData.hazard
        onColor: Theme.telltaleGreen
    }
}
