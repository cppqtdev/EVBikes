import QtQuick
import ClusterCore
import ClusterBackend
import ClusterComponents

// Tabs: messages, music, reminders. Message text is hidden while moving.
PageBase {
    id: page

    pageId: Router.menuMisc

    property int tab: Router.subIndex
    readonly property bool rowFocus: Router.subLevel > 0

    TabStrip {
        x: (Theme.screenWidth - width) / 2
        y: 92
        first: qsTr("message")
        second: qsTr("music")
        third: qsTr("reminder")
        current: page.tab
    }

    Column {
        x: 645 - 140
        y: 133
        spacing: 6
        visible: page.tab === 0

        Repeater {
            model: PhoneListData.contactCount

            MessageRow {
                initial: Format.contactInitial(index)
                name: Format.contactName(index)
                body: VehicleData.speedKmh > 0 ? qsTr("Stop to read") : Format.contactBody(index)
                avatarColor: "#2F8A6C"
                selected: page.rowFocus && Router.subLevel - 1 === index
            }
        }
    }

    // Nothing is built in, so an unpaired phone means an empty list. Say so
    // rather than leave the rows blank.
    Text {
        x: 0
        y: 170
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        visible: (page.tab === 0 && PhoneListData.contactCount === 0)
                 || (page.tab === 2 && PhoneListData.reminderCount === 0)
        text: page.tab === 0 ? qsTr("No messages yet") : qsTr("No reminders yet")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }

    Text {
        x: 0
        y: 274
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        visible: (page.tab === 0 && PhoneListData.contactCount > 0)
                 || (page.tab === 2 && PhoneListData.reminderCount > 0)
        text: page.rowFocus ? qsTr("OK call  \u00B7  BACK back") : qsTr("OK open the list")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    Column {
        x: 645 - 140
        y: 133
        spacing: 6
        visible: page.tab === 2

        Repeater {
            model: PhoneListData.reminderCount

            MessageRow {
                initial: Format.reminderInitial(index)
                name: Format.reminderName(index)
                body: Format.reminderBody(index)
                avatarColor: "#8A5A2F"
                selected: page.rowFocus && Router.subLevel - 1 === index
            }
        }
    }

    Item {
        width: Theme.screenWidth
        height: 300
        visible: page.tab === 1

        Text {
            x: 0
            y: 118
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("NOW PLAYING")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.italic: true
        }

        Image {
            x: 645 - 38
            y: 134
            source: "qrc:/assets/cluster/album_art.png"
        }

        Text {
            x: 0
            y: 216
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: PhoneData.trackTitle !== "" ? PhoneData.trackTitle : qsTr("Nothing playing")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 15
        }

        Text {
            x: 0
            y: 236
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: PhoneData.trackArtist
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }

        Icon { x: 580; y: 252; size: 18; source: "qrc:/assets/icons/18/prev.png"; color: "#8C9194" }
        Icon { x: 636; y: 251; size: 18; source: PhoneData.mediaPlaying ? "qrc:/assets/icons/18/pause.png" : "qrc:/assets/icons/18/play.png"; color: Theme.textPrimary }
        Icon { x: 692; y: 252; size: 18; source: "qrc:/assets/icons/18/next.png"; color: "#8C9194" }

        Rectangle {
            x: 560
            y: 278
            width: 170
            height: 1
            color: "#5C5C5C"
        }

        Rectangle {
            x: 560 + 170 * (PhoneData.trackDurationS > 0 ? PhoneData.trackPositionS / PhoneData.trackDurationS : 0) - 3
            y: 275
            width: 7
            height: 7
            radius: 3.5
            color: Theme.textPrimary
        }
    }
}
