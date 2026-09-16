import QtQuick
import ClusterCore
import ClusterBackend
import ClusterComponents

// Tabs: messages, music, reminders. Message text is hidden while moving.
PageBase {
    id: page

    pageId: Router.menuMisc

    property int tab: Router.subIndex

    ListModel {
        id: messages
        ListElement { initial: "K"; name: "Karan"; body: "Reached the office, see you soon" }
        ListElement { initial: "A"; name: "Akash"; body: "Lunch at 1?" }
        ListElement { initial: "M"; name: "Myra"; body: "Call me when you are free" }
    }

    ListModel {
        id: reminders
        ListElement { initial: "S"; name: "Service due"; body: "In 240 km" }
        ListElement { initial: "I"; name: "Insurance renewal"; body: "12 November" }
        ListElement { initial: "T"; name: "Tyre check"; body: "Every 15 days" }
    }

    TabStrip {
        x: 500
        y: 92
        first: qsTr("message")
        second: qsTr("music")
        third: qsTr("reminder")
        current: page.tab
    }

    Column {
        x: 510
        y: 133
        spacing: 5
        visible: page.tab === 0

        Repeater {
            model: messages

            MessageRow {
                initial: model.initial
                name: model.name
                body: VehicleData.speedKmh > 0 ? qsTr("Stop to read") : model.body
                avatarColor: "#2F8A6C"
            }
        }
    }

    Column {
        x: 510
        y: 133
        spacing: 5
        visible: page.tab === 2

        Repeater {
            model: reminders

            MessageRow {
                initial: model.initial
                name: model.name
                body: model.body
                avatarColor: "#8A5A2F"
            }
        }
    }

    Item {
        width: Theme.screenWidth
        height: 300
        visible: page.tab === 1

        Text {
            x: 0
            y: 120
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("NOW PLAYING")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.italic: true
        }

        Image {
            x: 598
            y: 137
            source: "qrc:/assets/cluster/album_art.png"
        }

        Text {
            x: 0
            y: 238
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: PhoneData.trackTitle !== "" ? PhoneData.trackTitle : qsTr("Nothing playing")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Text {
            x: 0
            y: 257
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: PhoneData.trackArtist
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }

        Icon { x: 574; y: 268; size: 18; source: "qrc:/assets/icons/18/prev.png"; color: "#8C9194" }
        Icon { x: 639; y: 267; size: 18; source: PhoneData.mediaPlaying ? "qrc:/assets/icons/18/pause.png" : "qrc:/assets/icons/18/play.png"; color: Theme.textPrimary }
        Icon { x: 707; y: 268; size: 18; source: "qrc:/assets/icons/18/next.png"; color: "#8C9194" }

        Rectangle {
            x: 542
            y: 289
            width: 213
            height: 1
            color: "#5B6164"
        }

        Rectangle {
            x: 542 + 213 * (PhoneData.trackDurationS > 0 ? PhoneData.trackPositionS / PhoneData.trackDurationS : 0) - 3
            y: 286
            width: 7
            height: 7
            radius: 3.5
            color: Theme.textPrimary
        }
    }
}
