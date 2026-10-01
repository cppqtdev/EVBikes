import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

PageBase {
    pageId: Router.menuSeat

    Image {
        x: 492
        y: 146 - SystemData.seatLevel * 6
        source: "qrc:/assets/cluster/seat.png"

        Behavior on y {
            NumberAnimation { duration: Theme.animNormal }
        }
    }

    Icon {
        x: 776
        y: 120
        size: 20
        source: "qrc:/assets/icons/20/nav.png"
        color: SystemData.seatLevel < 5 ? "#D4553A" : Theme.textMuted
    }

    Icon {
        x: 776
        y: 190
        size: 20
        source: "qrc:/assets/icons/20/nav.png"
        color: SystemData.seatLevel > 0 ? "#D4553A" : Theme.textMuted
        transform: Rotation {
            origin.x: 10
            origin.y: 10
            angle: 180
        }
    }

    GlassButton {
        x: 591
        y: 232
        width: 112
        height: 32
        text: qsTr("RESET")
        fontSize: 16
        selected: SystemData.seatLevel === 2
        glowColor: Theme.teal
    }

    Text {
        x: 812
        y: 158
        text: qsTr("Level ") + SystemData.seatLevel
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }
}
