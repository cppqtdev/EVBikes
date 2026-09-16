import QtQuick
import ClusterCore

// Pill-shaped list row with an initial avatar.
Item {
    id: row

    property string initial: ""
    property string name: ""
    property string body: ""
    property color avatarColor: "#2F8A6C"

    width: 280
    height: 47

    Rectangle {
        anchors.fill: parent
        radius: 23
        color: "#9EA3A5"
    }

    Rectangle {
        x: 1
        y: 1
        width: 278
        height: 45
        radius: 22
        color: "#0E1011"
    }

    Rectangle {
        x: 10
        y: 6
        width: 34
        height: 34
        radius: 17
        color: row.avatarColor

        Text {
            anchors.centerIn: parent
            text: row.initial
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
        }
    }

    Text {
        x: 60
        y: 3
        text: row.name
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 18
    }

    Text {
        x: 60
        y: 25
        width: 210
        elide: Text.ElideRight
        text: row.body
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }
}
