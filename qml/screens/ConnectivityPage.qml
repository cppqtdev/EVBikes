import QtQuick
import ClusterCore
import ClusterBackend
import ClusterComponents

PageBase {
    pageId: Router.menuConnectivity
    Text {
        x: 400; y: 78; width: 480; height: 28
        text: qsTr("Connections")
        color: Theme.textPrimary
        font.family: Theme.fontFamily; font.pixelSize: 22
    }
    Text {
        x: 400; y: 118; width: 480; height: 24
        text: !ConnectivityData.bluetoothAvailable ? qsTr("Bluetooth: external radio driver required")
            : ConnectivityData.bluetoothState === ConnectivityData.Pairing ? qsTr("Pairing with demo phone...")
            : ConnectivityData.bluetoothState === ConnectivityData.Connected ? qsTr("Demo phone connected")
            : qsTr("No phone paired")
        color: Theme.textSecondary
        font.family: Theme.fontFamily; font.pixelSize: 16
    }
    Rectangle {
        x: 400; y: 153; width: 230; height: 38; radius: 4
        color: ConnectivityData.bluetoothAvailable ? Theme.surfaceSelected : Theme.surfaceSunken
        Text {
            anchors.centerIn: parent
            text: ConnectivityData.bluetoothState === ConnectivityData.Connected ? qsTr("Disconnect demo phone") : qsTr("Pair demo phone")
            color: Theme.textPrimary
            font.family: Theme.fontFamily; font.pixelSize: 16
        }
        MouseArea {
            anchors.fill: parent
            enabled: ConnectivityData.bluetoothAvailable && VehicleData.speedKmh === 0 && !VehicleData.driveStale
            onClicked: {
                if (ConnectivityData.bluetoothState === ConnectivityData.Connected) ConnectivityData.disconnect()
                else ConnectivityData.pair()
            }
        }
    }
    Text {
        x: 400; y: 212; width: 480; height: 24
        text: qsTr("Wi-Fi: no supported radio configured")
        color: Theme.textMuted
        font.family: Theme.fontFamily; font.pixelSize: 16
    }
    Text {
        x: 400; y: 246; width: 490; height: 32
        text: ConnectivityData.simulated ? qsTr("Simulator only. Pairing controls require the bike to be stopped.")
                                         : qsTr("TRAVEO needs an external BLE / Wi-Fi module and driver.")
        color: Theme.textMuted
        font.family: Theme.fontFamily; font.pixelSize: 12
    }
}
