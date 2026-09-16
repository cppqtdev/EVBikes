import QtQuick
import ClusterCore

// Documents list; the middle row is the selected one. View only when stopped.
PageBase {
    id: page

    pageId: Router.menuDigilocker

    ListModel {
        id: docs
        ListElement { title: "Insurance" }
        ListElement { title: "Aadhar card" }
        ListElement { title: "Driving license" }
    }

    Repeater {
        model: docs

        Item {
            property int slot: (index - Router.subIndex + 4) % 3

            x: 512
            y: slot === 0 ? 119 : (slot === 1 ? 166 : 221)
            width: 273
            height: slot === 1 ? 45 : 36
            opacity: slot === 1 ? 1.0 : 0.35

            Behavior on y {
                NumberAnimation { duration: Theme.animNormal }
            }

            Rectangle {
                anchors.fill: parent
                radius: 4
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#282828" }
                    GradientStop { position: 1.0; color: "#1C1C1C" }
                }
            }

            Text {
                anchors.centerIn: parent
                text: model.title
                color: "#B8BDBF"
                font.family: Theme.fontFamily
                font.pixelSize: parent.slot === 1 ? 22 : 20
                font.bold: true
                font.italic: true
            }
        }
    }
}
