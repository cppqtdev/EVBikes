import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

PageBase {
    pageId: Router.menuSecurity

    ColorizedImage {
        x: 550
        y: 66
        source: "qrc:/assets/cluster/shield.png"
        color: "#4E4E4E"
        opacity: 0.8
    }

    GlassButton {
        x: 515
        y: 141
        width: 260
        height: 37
        text: qsTr("Anti-Theft Captures")
        selected: Router.subIndex === 0
        glowColor: Theme.red
        topColor: "#A8342E"
        bottomColor: "#6A1A18"
    }

    Rectangle {
        x: 757
        y: 130
        width: 22
        height: 22
        radius: 11
        color: "#E9E3E3"
        visible: SystemData.theftCaptures > 0

        Text {
            anchors.centerIn: parent
            text: "" + SystemData.theftCaptures
            color: "#8E1C22"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
        }
    }

    GlassButton {
        x: 515
        y: 199
        width: 260
        height: 37
        text: SystemData.antiTheftArmed ? qsTr("Activated ✓") : qsTr("Activation")
        selected: Router.subIndex === 1
        glowColor: Theme.teal
    }
}
