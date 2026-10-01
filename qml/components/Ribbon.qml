import QtQuick
import QtQuickUltralite.Extras
import ClusterCore

// Trapezoid ribbon title (WARNING, PROTOCOLS, CRASH DETECTED).
Item {
    id: ribbon

    property string text: ""
    property color topColor: Theme.goldTop
    property color bottomColor: Theme.goldBottom
    property font textFont: Qt.font({ family: Theme.fontFamily, pixelSize: 20 })

    width: 340
    height: 30

    ColorizedImage {
        source: "qrc:/assets/cluster/ribbon.png"
        color: ribbon.bottomColor
    }

    Item {
        width: 340
        height: 14
        clip: true

        ColorizedImage {
            source: "qrc:/assets/cluster/ribbon.png"
            color: ribbon.topColor
        }
    }

    Text {
        anchors.centerIn: parent
        text: ribbon.text
        color: Theme.textPrimary
        font: ribbon.textFont
    }
}
