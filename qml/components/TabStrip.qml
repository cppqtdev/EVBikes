import QtQuick
import ClusterCore

// Three-part tab strip (e.g. message | music | reminder).
Item {
    id: tabs

    property string first: ""
    property string second: ""
    property string third: ""
    property int current: 0

    width: 290
    height: 32

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: "#212121"
    }

    Rectangle {
        x: 2 + tabs.current * 96
        y: 2
        width: 94
        height: 28
        radius: 5
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2F8A6C" }
            GradientStop { position: 1.0; color: "#1D5E49" }
        }

        Behavior on x {
            NumberAnimation { duration: Theme.animNormal }
        }
    }

    Row {
        x: 2
        y: 2

        Repeater {
            model: 3

            Text {
                width: 96
                height: 28
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: index === 0 ? tabs.first : (index === 1 ? tabs.second : tabs.third)
                color: index === tabs.current ? Theme.textPrimary : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 15
            }
        }
    }
}
