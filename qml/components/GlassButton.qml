import QtQuick
import QtQuickUltralite.Extras
import ClusterCore

// Dark glass button with an optional coloured glow when selected.
Item {
    id: button

    property string text: ""
    property bool selected: false
    property color glowColor: Theme.goldTop
    property color topColor: "#404040"
    property color bottomColor: "#282828"
    property int fontSize: 22

    // The glow is pre-rendered art drawn at its own size, never scaled: a blur
    // stretched at runtime costs fill rate on the board and comes out soft.
    // Buttons here run from 112 to 273 wide, so there are two sizes and the
    // narrow ones stop wearing a halo three times their own width.
    readonly property bool wide: width > 180

    width: 260
    height: 38

    ColorizedImage {
        anchors.centerIn: parent
        width: button.wide ? 320 : 150
        height: button.wide ? 200 : 40
        source: button.wide ? "qrc:/assets/images/glow_blob_320x200.png"
                            : "qrc:/assets/images/glow_blob_150x40.png"
        color: button.glowColor
        opacity: button.selected ? 0.35 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animNormal }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 4
        gradient: Gradient {
            GradientStop { position: 0.0; color: button.topColor }
            GradientStop { position: 1.0; color: button.bottomColor }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: button.selected ? "#C9CDCF" : "#5B6164"
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: button.text
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: button.fontSize
    }
}
