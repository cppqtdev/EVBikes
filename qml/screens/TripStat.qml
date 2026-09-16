import QtQuick
import ClusterCore

Column {
    id: stat

    property string title: ""
    property string value: ""

    width: 150

    Text {
        width: stat.width
        horizontalAlignment: Text.AlignHCenter
        text: stat.title
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 18
    }

    Text {
        width: stat.width
        horizontalAlignment: Text.AlignHCenter
        text: stat.value
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 18
    }
}
