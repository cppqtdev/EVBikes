import QtQuick
import ClusterCore
import ClusterBackend
import ClusterComponents

// Documents list; the middle row is the selected one. View only when stopped.
PageBase {
    id: page

    pageId: Router.menuDigilocker

    readonly property font selectedFont: Qt.font({ family: Theme.fontFamily, pixelSize: 22, bold: true, italic: true })
    readonly property font restFont: Qt.font({ family: Theme.fontFamily, pixelSize: 20, bold: true, italic: true })

    DemoNotice {
        subject: qsTr("Your documents")
    }

    Repeater {
        //  Three fixed titles carried by the delegate: a Qt for MCUs ListModel
        //  reaches its roles only through a required property, and the model
        //  itself cannot be swapped for a count.
        model: 3

        Item {
            id: row

            property int slot: (index - Router.subIndex + 4) % 3
            readonly property string title: index === 0 ? qsTr("Insurance")
                                          : (index === 1 ? qsTr("Aadhar card")
                                                         : qsTr("Driving license"))

            visible: SystemData.demoMode
            x: 512
            y: slot === 0 ? 119 : (slot === 1 ? 166 : 221)
            width: 273
            height: slot === 1 ? 45 : 36
            opacity: slot === 1 ? 1.0 : 0.35

            Behavior on y {
                NumberAnimation {
                    duration: Theme.animNormal
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 4
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#282828"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#1C1C1C"
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: row.title
                color: "#B8BDBF"
                font: row.slot === 1 ? page.selectedFont : page.restFont
            }
        }
    }
}
