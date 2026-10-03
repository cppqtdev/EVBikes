import QtQuick
import ClusterCore
import ClusterBackend

// Extra warning lamps from the project CAN powertrain frame.
Row {
    id: warnings
    property int iconSize: 24
    spacing: 2
    height: iconSize
    Repeater {
        model: 16
        Telltale {
            size: warnings.iconSize
            readonly property bool applicable: index < 5 ? VehicleData.powertrain === VehicleData.Petrol
                : ((index >= 6 && index <= 10) || index === 15 ? VehicleData.powertrain === VehicleData.Electric : true)
            visible: applicable && !VehicleData.powertrainStale && (VehicleData.telltaleFlags & (1 << index)) !== 0
            active: visible
            activeColor: index === 1 || index === 2 || index === 8 || index === 11 ? Theme.telltaleRed
                       : (index === 13 || index === 15 ? Theme.telltaleGreen : Theme.telltaleAmber)
            source: index === 0 ? "qrc:/assets/icons/32/bike_check-engine.png"
                  : index === 1 ? "qrc:/assets/icons/32/bike_oil-pressure.png"
                  : index === 2 ? "qrc:/assets/icons/32/bike_engine-temperature.png"
                  : index === 3 ? "qrc:/assets/icons/32/bike_low-fuel.png"
                  : index === 4 ? "qrc:/assets/icons/32/bike_efi.png"
                  : index === 5 ? "qrc:/assets/icons/32/bike_service-maintenance.png"
                  : index === 6 ? "qrc:/assets/icons/32/bike_motor-fault.png"
                  : index === 7 ? "qrc:/assets/icons/32/bike_motor-temperature.png"
                  : index === 8 ? "qrc:/assets/icons/32/bike_battery-temperature.png"
                  : index === 9 ? "qrc:/assets/icons/32/bike_charging-fault.png"
                  : index === 10 ? "qrc:/assets/icons/32/bike_reduced-power.png"
                  : index === 11 ? "qrc:/assets/icons/32/bike_brake-warning.png"
                  : index === 12 ? "qrc:/assets/icons/32/bike_traction-control.png"
                  : index === 13 ? "qrc:/assets/icons/32/bike_cruise-control.png"
                  : index === 14 ? "qrc:/assets/icons/32/bike_immobilizer-security.png"
                  : "qrc:/assets/icons/32/bike_charging.png"
        }
    }
}
