import QtQuick
import ClusterCore

// Three visible menu tiles (previous, current, next) and page dots.
Item {
    id: carousel

    property int index: Router.menuIndex

    width: Theme.screenWidth
    height: 70

    Rectangle {
        x: 465
        y: 0
        width: 108
        height: 34
        color: "#181818"
        opacity: 0.8
    }

    Text {
        x: 465
        y: 7
        width: 108
        horizontalAlignment: Text.AlignHCenter
        text: Router.menuTitle(Router.wrap(carousel.index - 1))
        color: "#5E666A"
        elide: Text.ElideRight
        font.family: Theme.fontFamily
        font.pixelSize: 15
        font.italic: true
    }

    Rectangle {
        x: 580
        y: 0
        width: 129
        height: 34
        color: Theme.surfaceSelected
    }

    Text {
        x: 580
        y: 5
        width: 129
        horizontalAlignment: Text.AlignHCenter
        text: Router.menuTitle(carousel.index)
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 18
        font.italic: true
    }

    Rectangle {
        x: 716
        y: 0
        width: 108
        height: 34
        color: "#181818"
        opacity: 0.8
    }

    Text {
        x: 716
        y: 7
        width: 108
        horizontalAlignment: Text.AlignHCenter
        text: Router.menuTitle(Router.wrap(carousel.index + 1))
        color: "#5E666A"
        elide: Text.ElideRight
        font.family: Theme.fontFamily
        font.pixelSize: 15
        font.italic: true
    }

    Rectangle { x: 628; y: 44; width: 5; height: 5; radius: 2.5; color: "#5B6164" }
    Rectangle { x: 641; y: 44; width: 5; height: 5; radius: 2.5; color: Theme.textPrimary }
    Rectangle { x: 654; y: 44; width: 5; height: 5; radius: 2.5; color: "#5B6164" }

    FadeLine {
        x: 500
        y: 57
        width: 280
    }
}
