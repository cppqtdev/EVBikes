import QtQuick
import ClusterCore

Item {
    id: row

    property string title: ""
    property string value: ""
    property alias iconSource: rowIcon.source
    property bool selected: false

    readonly property font titleFont: Qt.font({ family: Theme.fontFamily, pixelSize: Theme.fontBody })
    readonly property font titleBoldFont: Qt.font({ family: Theme.fontFamily, pixelSize: Theme.fontBody, bold: true })

    width: 480
    height: 52

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusM
        color: row.selected ? "#1D4A3E" : "#00000000"

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Rectangle {
        visible: row.selected
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - 16
        radius: 2
        color: Theme.accent
    }

    Icon {
        id: rowIcon
        x: Theme.spaceL
        anchors.verticalCenter: parent.verticalCenter
        size: 24
        color: row.selected ? Theme.accent : Theme.textSecondary
    }

    Text {
        anchors.left: rowIcon.right
        anchors.leftMargin: Theme.spaceM
        anchors.verticalCenter: parent.verticalCenter
        text: row.title
        color: Theme.textPrimary
        font: row.selected ? row.titleBoldFont : row.titleFont
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceL
        anchors.verticalCenter: parent.verticalCenter
        text: row.value
        color: row.selected ? Theme.accent : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
    }
}
