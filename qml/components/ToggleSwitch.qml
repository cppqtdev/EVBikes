import QtQuick
import ClusterCore

Item {
    id: toggle

    property bool checked: false

    width: 86
    height: 38

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: toggle.checked ? "#4E9E6E" : "#3A3E40" }
            GradientStop { position: 1.0; color: toggle.checked ? "#9CF0B6" : "#4A4F52" }
        }
    }

    Rectangle {
        x: toggle.checked ? 3 : toggle.width - width - 3
        y: 3
        width: 32
        height: 32
        radius: 16
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#9A9FA2" }
            GradientStop { position: 1.0; color: "#5C6164" }
        }

        Behavior on x {
            NumberAnimation { duration: Theme.animNormal }
        }
    }
}
