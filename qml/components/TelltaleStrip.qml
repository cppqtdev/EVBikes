import QtQuick
import ClusterCore
import ClusterBackend

// Main lamps remain visible in their disabled colour. Extra fault lamps
// appear on demand. A shared square box and gap keep both groups consistent.
//
//  The two groups sit on their own rows. The top row is what a rider sees on
//  every ride, so it holds its place whether the lamp is lit or not. The row
//  under it is for faults, which should read as an event rather than as part
//  of the furniture, so it is empty most of the time and centres whatever is
//  actually on.
Item {
    id: strip

    property bool selfTest: false
    readonly property int iconSize: 32
    //  Two pixels ran the lamps together into one band. This is the air that
    //  lets each of them be read as its own thing.
    readonly property int iconGap: 14
    readonly property int headerY: 12
    readonly property int faultY: 52

    width: Theme.screenWidth
    height: faultY + iconSize

    Telltale {
        x: 422; y: strip.headerY
        size: strip.iconSize
        source: "qrc:/assets/icons/32/tt_left.png"
        blinking: false
        active: strip.selfTest || VehicleData.indicatorLeft || VehicleData.hazard
        activeColor: Theme.telltaleGreen
    }
    Telltale {
        x: 866; y: strip.headerY
        size: strip.iconSize
        source: "qrc:/assets/icons/32/tt_right.png"
        blinking: false
        active: strip.selfTest || VehicleData.indicatorRight || VehicleData.hazard
        activeColor: Theme.telltaleGreen
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 16
        y: strip.headerY
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
    }

    //  Out of the way while an alert card is up. Every one of those cards
    //  starts between y 65 and 81 and this row ends at 84, so they always
    //  meet. The card is modal, it dims everything behind it and it names the
    //  fault in large type, so the row has nothing to add while it is there
    //  -- and it comes straight back when the card is dismissed, because the
    //  lamps are the standing state and the card was only the event.
    VehicleWarnings {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 16
        y: strip.faultY
        visible: !AlertData.popupVisible
        iconSize: strip.iconSize
        spacing: strip.iconGap
    }
}
