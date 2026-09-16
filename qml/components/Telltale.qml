import QtQuick
import ClusterCore

Item {
    id: telltale

    property alias source: icon.source
    property bool on: false
    property int size: 26
    property color onColor: Theme.telltaleGreen
    property color offColor: Theme.telltaleOff

    width: size
    height: size

    Icon {
        id: icon
        anchors.centerIn: parent
        size: telltale.size
        color: telltale.on ? telltale.onColor : telltale.offColor
    }
}
