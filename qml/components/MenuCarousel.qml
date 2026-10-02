import QtQuick
import ClusterCore

// Three fixed slots share Router.menuIndex with the active page. Keeping the
// selection in one place avoids a second PathView index drifting out of sync.
Item {
    id: carousel
    width: Theme.screenWidth
    height: 70

    Repeater {
        model: 3
        Rectangle {
            x: 465 + index * 120
            width: 120
            height: 34
            color: index === 1 ? Theme.surfaceSelected : "#181818"
            Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Router.menuTitle((Router.menuIndex + index - 1 + Router.menuCount) % Router.menuCount)
                color: index === 1 ? Theme.textPrimary : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.italic: true
                elide: Text.ElideRight
            }
            MouseArea {
                anchors.fill: parent
                onClicked: Router.moveMenu(index - 1)
            }
        }
    }

    Icon {
        x: 433; y: 8; size: 18
        source: "qrc:/assets/icons/18/chevron.png"
        color: Theme.textSecondary
        transform: Scale { origin.x: 9; origin.y: 9; xScale: -1 }
    }
    MouseArea {
        x: 420; y: -5; width: 44; height: 44
        onClicked: Router.moveMenu(-1)
    }
    Icon {
        x: 839; y: 8; size: 18
        source: "qrc:/assets/icons/18/chevron.png"
        color: Theme.textSecondary
    }
    MouseArea {
        x: 826; y: -5; width: 44; height: 44
        onClicked: Router.moveMenu(1)
    }

    Repeater {
        model: 10
        Rectangle {
            x: 583 + index * 13; y: 44
            width: 5; height: 5; radius: 2
            color: index === Router.menuIndex ? Theme.textPrimary : "#5C5C5C"
        }
    }
    FadeLine { x: 500; y: 57; width: 280 }
}
