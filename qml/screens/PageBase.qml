import QtQuick
import ClusterCore

// Menu page container: shown when the carousel is open on this entry.
Item {
    id: page

    property int pageId: 0
    property bool current: Router.menuOpen && Router.menuIndex === pageId

    width: Theme.screenWidth
    height: 300
    opacity: current ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.animNormal }
    }
}
