import QtQuick
import ClusterCore
import ClusterBackend

// Bluetooth + outside temperature (left), signal + clock (right).
Item {
    id: status

    width: Theme.screenWidth
    height: 64

    Icon {
        x: 251
        y: 20
        size: 28
        source: "qrc:/assets/icons/28/bluetooth.png"
        color: PhoneData.connected ? Theme.textPrimary : Theme.textMuted
    }

    Text {
        id: tempValue
        x: 305
        y: 18
        text: "" + VehicleData.ambientTempC
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 24
    }

    Text {
        x: tempValue.x + tempValue.width + 1
        y: 12
        text: "°"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 18
    }

    Text {
        x: tempValue.x + tempValue.width + 5
        y: 25
        text: "C"
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 15
    }

    Icon {
        x: 939
        y: 25
        size: 22
        source: "qrc:/assets/icons/22/signal_full.png"
        color: PhoneData.connected ? Theme.textPrimary : Theme.textMuted
    }

    Text {
        id: clock
        x: 980
        y: 20
        visible: SystemData.clockValid
        text: Format.pad2(SystemData.use24Hour ? SystemData.hours : (SystemData.hours % 12 === 0 ? 12 : SystemData.hours % 12))
              + ":" + Format.pad2(SystemData.minutes)
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 22
    }

    Text {
        x: clock.x + clock.width + 1
        y: 27
        visible: SystemData.clockValid && !SystemData.use24Hour
        text: SystemData.hours < 12 ? "am" : "pm"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }
}
