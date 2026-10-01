import QtQuick
import ClusterCore

// The menu strip. A PathView so moving between pages slides the titles along
// instead of re-labelling three fixed tiles, with chevrons either side showing
// that left and right go somewhere.
Item {
    id: carousel

    property int index: Router.menuIndex
    readonly property int centerX: 645
    readonly property int cellWidth: 120
    readonly property int cellHeight: 34

    width: Theme.screenWidth
    height: 70

    PathView {
        id: strip

        x: carousel.centerX - 180
        y: 0
        width: 360
        height: carousel.cellHeight
        clip: true

        model: Router.menuCount
        pathItemCount: 3
        currentIndex: carousel.index
        interactive: false
        highlightMoveDuration: Theme.animNormal
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange

        path: Path {
            startX: 0
            startY: carousel.cellHeight / 2
            PathLine { x: 360; y: carousel.cellHeight / 2 }
        }

        delegate: Item {
            id: cell

            // How far this title is from the selected one, the short way round.
            readonly property int offset: {
                var step = index - strip.currentIndex
                if (step > Router.menuCount / 2)
                    step -= Router.menuCount
                if (step < -Router.menuCount / 2)
                    step += Router.menuCount
                return step
            }
            readonly property bool selected: offset === 0

            width: carousel.cellWidth
            height: carousel.cellHeight
            opacity: selected ? 1.0 : (Math.abs(offset) === 1 ? 0.85 : 0.2)

            Behavior on opacity {
                NumberAnimation { duration: Theme.animFast }
            }

            Rectangle {
                anchors.fill: parent
                color: cell.selected ? Theme.surfaceSelected : "#181818"
                opacity: cell.selected ? 1.0 : 0.8
            }

            Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Router.menuTitle(index)
                color: cell.selected ? Theme.textPrimary : "#5E666A"
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: cell.selected ? 18 : 15
                font.italic: true
            }
        }
    }

    Icon {
        x: carousel.centerX - 212
        y: 8
        size: 18
        source: "qrc:/assets/icons/18/chevron.png"
        color: "#5E666A"

        transform: Scale {
            origin.x: 9
            origin.y: 9
            xScale: -1
        }
    }

    Icon {
        x: carousel.centerX + 194
        y: 8
        size: 18
        source: "qrc:/assets/icons/18/chevron.png"
        color: "#5E666A"
    }

    Repeater {
        model: 3

        Rectangle {
            x: 628 + index * 13
            y: 44
            width: 5
            height: 5
            radius: 2.5
            color: index === Math.floor(carousel.index / 3) ? Theme.textPrimary : "#5C5C5C"

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }
    }

    FadeLine {
        x: 500
        y: 57
        width: 280
    }
}
