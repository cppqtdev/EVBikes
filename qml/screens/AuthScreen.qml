import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// Rider profile selection and fingerprint unlock.
Item {
    id: auth

    property int authState: SystemData.authState
    property int elapsedMs: SystemData.authElapsedMs
    property int dots: Math.floor(auth.elapsedMs / 120) % 8

    width: Theme.screenWidth
    height: Theme.screenHeight

    onElapsedMsChanged: {
        if (auth.authState === SystemData.AuthMatched && elapsedMs >= 1200)
            Router.finishAuth()
    }

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        opacity: auth.authState === SystemData.AuthIdle ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animNormal }
        }

        Repeater {
            model: 3

            Item {
                id: tile

                property bool selected: SystemData.profileIndex === index
                property int centerX: index === 0 ? 500 : (index === 1 ? 651 : 805)

                x: centerX - 60
                y: 118
                width: 120
                height: 150

                ColorizedImage {
                    x: 7
                    y: 10
                    visible: tile.selected
                    source: "qrc:/assets/cluster/avatar_106.png"
                    color: "#DADDDE"
                }

                ColorizedImage {
                    x: 14
                    y: 13
                    visible: !tile.selected
                    source: "qrc:/assets/cluster/avatar_92.png"
                    color: "#8C9194"
                }

                Text {
                    y: 122
                    width: 120
                    horizontalAlignment: Text.AlignHCenter
                    text: Format.profileName(index)
                    color: tile.selected ? Theme.textPrimary : "#7B8285"
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }
            }
        }
    }

    Row {
        x: 0
        y: 204
        width: Theme.screenWidth
        visible: auth.authState !== SystemData.AuthIdle

        Item {
            width: (Theme.screenWidth - statusText.width - 44) / 2
            height: 1
        }

        Text {
            id: statusText
            text: auth.authState === SystemData.AuthScanning ? qsTr("Scan")
                : (auth.authState === SystemData.AuthDenied ? qsTr("No access") : qsTr("Match"))
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: 34
        }

        Item {
            width: 44
            height: 44

            Repeater {
                model: 8

                Rectangle {
                    visible: auth.authState === SystemData.AuthScanning
                    x: 22 + 10 * Math.cos(index * 0.785) - 2
                    y: 24 + 10 * Math.sin(index * 0.785) - 2
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.white
                    opacity: ((index - auth.dots + 8) % 8) / 8
                }
            }

            Icon {
                x: 8
                y: 10
                size: 32
                visible: auth.authState === SystemData.AuthDenied
                source: "qrc:/assets/icons/32/triangle.png"
                color: Theme.red
            }

            Icon {
                x: 8
                y: 10
                size: 32
                visible: auth.authState === SystemData.AuthMatched
                source: "qrc:/assets/icons/32/check.png"
                color: Theme.teal
            }
        }
    }

    BootChrome {
        printColor: auth.authState === SystemData.AuthDenied ? Theme.red
                  : (auth.authState === SystemData.AuthMatched ? Theme.teal : "#5FD6B4")
    }
}
