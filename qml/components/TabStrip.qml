import QtQuick
import ClusterCore

// Three-part tab strip (e.g. message | music | reminder).
// Each cell is as wide as its own label plus padding, so a long label such as
// "Shortcut keys" is not cut by a fixed cell width.
Item {
    id: tabs

    property string first: ""
    property string second: ""
    property string third: ""
    property int current: 0

    property int padding: 16
    property int cellHeight: 30
    property int inset: 3
    property int labelSize: 15

    readonly property int firstWidth: Math.round(firstLabel.contentWidth) + padding * 2
    readonly property int secondWidth: Math.round(secondLabel.contentWidth) + padding * 2
    readonly property int thirdWidth: Math.round(thirdLabel.contentWidth) + padding * 2

    readonly property int currentX: tabs.current === 0 ? 0
                                  : (tabs.current === 1 ? tabs.firstWidth
                                                        : tabs.firstWidth + tabs.secondWidth)
    readonly property int currentWidth: tabs.current === 0 ? tabs.firstWidth
                                      : (tabs.current === 1 ? tabs.secondWidth : tabs.thirdWidth)

    width: firstWidth + secondWidth + thirdWidth + inset * 2
    height: cellHeight + inset * 2

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: "#212121"
    }

    Rectangle {
        x: tabs.inset + tabs.currentX
        y: tabs.inset
        width: tabs.currentWidth
        height: tabs.cellHeight
        radius: 5
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2F8A6C" }
            GradientStop { position: 1.0; color: "#1D5E49" }
        }

        Behavior on x {
            NumberAnimation { duration: Theme.animNormal }
        }

        Behavior on width {
            NumberAnimation { duration: Theme.animNormal }
        }
    }

    Text {
        id: firstLabel
        x: tabs.inset + (tabs.firstWidth - contentWidth) / 2
        y: tabs.inset
        height: tabs.cellHeight
        verticalAlignment: Text.AlignVCenter
        text: tabs.first
        color: tabs.current === 0 ? Theme.textPrimary : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: tabs.labelSize
    }

    Text {
        id: secondLabel
        x: tabs.inset + tabs.firstWidth + (tabs.secondWidth - contentWidth) / 2
        y: tabs.inset
        height: tabs.cellHeight
        verticalAlignment: Text.AlignVCenter
        text: tabs.second
        color: tabs.current === 1 ? Theme.textPrimary : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: tabs.labelSize
    }

    Text {
        id: thirdLabel
        x: tabs.inset + tabs.firstWidth + tabs.secondWidth + (tabs.thirdWidth - contentWidth) / 2
        y: tabs.inset
        height: tabs.cellHeight
        verticalAlignment: Text.AlignVCenter
        text: tabs.third
        color: tabs.current === 2 ? Theme.textPrimary : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: tabs.labelSize
    }
}
