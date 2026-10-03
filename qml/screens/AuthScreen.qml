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
        opacity: auth.authState === SystemData.AuthIdle && !Router.pinMode ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animNormal
            }
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

                MouseArea {
                    anchors.fill: parent
                    onClicked: SystemData.selectProfile(index)
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

    //  PIN entry. Four boxes, the digit under the cursor changes with up and
    //  down, the cursor moves with left and right. Sizes 16 and 34 are the two
    //  this screen already uses, so the keypad adds no font configuration.
    Item {
        id: pad

        readonly property int boxWidth: 64
        readonly property int boxHeight: 84
        readonly property int boxGap: 20
        readonly property int firstX: (Theme.screenWidth - 4 * boxWidth - 3 * boxGap) / 2

        width: Theme.screenWidth
        height: Theme.screenHeight
        opacity: Router.pinMode ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animNormal
            }
        }

        Text {
            y: 108
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("ENTER PIN")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Repeater {
            model: 4

            Item {
                id: box

                readonly property bool here: Router.pinCursor === index

                x: pad.firstX + index * (pad.boxWidth + pad.boxGap)
                y: 136
                width: pad.boxWidth
                height: pad.boxHeight

                //  Rectangle.border does not exist here, so the outline is a
                //  filled rectangle with the face drawn inset on top of it.
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: box.here ? Theme.teal : "#3E3E3E"
                }

                Rectangle {
                    x: 2
                    y: 2
                    width: pad.boxWidth - 4
                    height: pad.boxHeight - 4
                    radius: 5
                    color: "#191919"
                }

                Text {
                    y: 24
                    width: pad.boxWidth
                    horizontalAlignment: Text.AlignHCenter
                    text: Format.digitAt(Router.pinValue, 3 - index)
                    color: box.here ? Theme.textPrimary : "#9BA1A4"
                    font.family: Theme.fontFamily
                    font.pixelSize: 34
                }

                //  Which digit the cursor is on, read without counting boxes.
                Rectangle {
                    x: (pad.boxWidth - 18) / 2
                    y: pad.boxHeight - 10
                    width: 18
                    height: 2
                    visible: box.here
                    color: Theme.teal
                }
            }
        }

        Text {
            y: 236
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: SystemData.pinAttemptsLeft === 1 ? qsTr("1 try left")
                : (SystemData.pinAttemptsLeft < 1 ? qsTr("Locked")
                                                  : qsTr("Tries left: ") + SystemData.pinAttemptsLeft)
            color: SystemData.pinAttemptsLeft <= 1 ? Theme.red : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Text {
            y: 266
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("↑ ↓ digit   ← → move   OK unlock   BACK cancel")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }
    }

    //  How to get to the keypad when there is no key.
    Text {
        y: 300
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        visible: auth.authState === SystemData.AuthIdle && !Router.pinMode
        text: qsTr("No key?  Press MODE to enter your PIN")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    BootChrome {
        printColor: auth.authState === SystemData.AuthDenied ? Theme.red
                  : (auth.authState === SystemData.AuthMatched ? Theme.teal : "#5FD6B4")
    }

    MouseArea {
        x: 555
        y: 260
        width: 170
        height: 125
        enabled: auth.authState !== SystemData.AuthScanning && !Router.pinMode
        onClicked: SystemData.startScan()
    }
}
