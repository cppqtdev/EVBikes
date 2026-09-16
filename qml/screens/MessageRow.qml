import QtQuick
import ClusterCore

// Pill-shaped list row with an initial avatar.
Item {
    id: row

    property string initial: ""
    property string name: ""
    property string body: ""
    property color avatarColor: "#2F8A6C"
    property bool selected: false

    width: 280
    height: 42

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: row.selected ? Theme.accent : "#6E7375"

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Rectangle {
        x: 1
        y: 1
        width: row.width - 2
        height: row.height - 2
        radius: (row.height - 2) / 2
        color: row.selected ? "#16221F" : "#0E1011"

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Rectangle {
        x: 8
        y: 5
        width: 32
        height: 32
        radius: 16
        color: row.avatarColor

        Text {
            anchors.centerIn: parent
            text: row.initial
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
        }
    }

    Text {
        x: 50
        y: 5
        width: 220
        elide: Text.ElideRight
        text: row.name
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 15
    }

    Text {
        x: 50
        y: 23
        width: 220
        elide: Text.ElideRight
        text: row.body
        color: row.selected ? Theme.textPrimary : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
}
