import QtQuick
import ClusterCore

// Microphone, recentre and layers: the controls that belong to the map.
//
// One definition, because both riding layouts carry them and two copies of a
// thing like this drift apart -- which is how the hexagon layout ended up
// without them at all.
Item {
    id: controls

    property int buttonSize: 30
    property int gap: 13

    width: 3 * buttonSize + 2 * gap
    height: buttonSize

    Repeater {
        model: 3

        Item {
            x: index * (controls.buttonSize + controls.gap)
            width: controls.buttonSize
            height: controls.buttonSize

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#2E2E2E"
                opacity: 0.8
            }

            Icon {
                anchors.centerIn: parent
                size: 18
                source: index === 0 ? "qrc:/assets/icons/18/mic.png"
                      : (index === 1 ? "qrc:/assets/icons/18/target.png" : "qrc:/assets/icons/18/layers.png")
                color: "#C3C8CA"
            }
        }
    }
}
