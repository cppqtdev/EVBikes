import QtQuick
import QtQuickUltralite.Extras
import ClusterCore

// Trapezoid ribbon title (WARNING, PROTOCOLS, CRASH DETECTED).
Item {
    id: ribbon

    property string text: ""
    property color topColor: Theme.goldTop
    property color bottomColor: Theme.goldBottom
    property int fontSize: 20
    property bool bold: false
    property bool italic: false

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
        font.family: Theme.fontFamily
        font.pixelSize: ribbon.fontSize
        font.bold: ribbon.bold
        font.italic: ribbon.italic
    }
}
