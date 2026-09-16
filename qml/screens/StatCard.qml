import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterComponents

// Green glass card with an icon and two centred text lines.
Item {
    id: card

    property string title: ""
    property string value: ""
    property alias iconSource: cardIcon.source

    width: 205
    height: 70

    ColorizedImage {
        anchors.centerIn: parent
        width: 260
        height: 120
        source: "qrc:/assets/images/glow_blob_260x120.png"
        color: "#3E7A55"
        opacity: 0.35
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2B3A31" }
            GradientStop { position: 1.0; color: "#344E3E" }
        }
    }

    Icon {
        id: cardIcon
        x: 12
        y: 17
        size: 36
        color: Theme.textPrimary
    }

    Column {
        x: 56
        y: 12
        width: card.width - 64

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: card.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: card.value
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }
    }
}
