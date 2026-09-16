import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// 3D-looking terrain grid with the route, plus phone navigation info.
Item {
    id: map

    width: Theme.screenWidth
    height: Theme.screenHeight

    ColorizedImage {
        x: 310
        y: 55
        source: "qrc:/assets/cluster/terrain.png"
        color: "#4FD9B2"
        opacity: 0.6
    }

    ColorizedImage {
        x: 310
        y: 55
        source: Format.routeImage(NavigationData.maneuver)
        color: Theme.white
        visible: NavigationData.active
    }

    ColorizedImage {
        x: 616
        y: 295
        source: "qrc:/assets/cluster/nav_cursor.png"
        color: Theme.white
    }

    Item {
        width: Theme.screenWidth
        height: 120
        visible: NavigationData.active

        Icon {
            x: 556
            y: 68
            size: 18
            source: "qrc:/assets/icons/18/flag.png"
            color: Theme.white
        }

        Text {
            id: roadText
            x: 578
            y: 66
            width: 170
            elide: Text.ElideRight
            text: NavigationData.roadName
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Rectangle {
            x: 560
            y: 88
            width: 162
            height: 1
            color: "#8C9194"
        }

        Icon {
            x: 588
            y: 94
            size: 28
            source: Format.turnIcon(NavigationData.maneuver)
            color: Theme.textPrimary
        }

        Text {
            x: 620
            y: 92
            text: Format.distanceValue(NavigationData.distanceToManeuverM) + " "
                  + Format.distanceUnit(NavigationData.distanceToManeuverM)
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 26
        }

        Repeater {
            model: 3

            Item {
                x: 771 + index * 43
                y: 61
                width: 30
                height: 30

                Rectangle {
                    anchors.fill: parent
                    radius: 15
                    color: "#2E2E2E"
                    opacity: 0.8
                }

                Icon {
                    anchors.centerIn: parent
                    size: 18
                    source: index === 0 ? "qrc:/assets/icons/18/mic.png"
                          : (index === 1 ? "qrc:/assets/icons/18/target.png" : "qrc:/assets/icons/18/layers.png")
                    color: "#C3C8CA"
                }
            }
        }
    }

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: !NavigationData.active

        Text {
            x: 0
            y: 72
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: PhoneData.connected ? qsTr("Start a route in the app") : qsTr("Connect your phone to navigate")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Repeater {
            model: 5

            Item {
                property bool big: index === 2

                x: index < 2 ? 494 + index * 52 : (index === 2 ? 598 : 674 + (index - 3) * 52)
                y: big ? 248 : 262
                width: big ? 70 : 48
                height: big ? 62 : 48

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: parent.big ? "#323232" : "#202020"
                    opacity: parent.big ? 1.0 : 0.8
                }

                Icon {
                    x: (parent.width - size) / 2
                    y: 5
                    size: 18
                    visible: !parent.big
                    source: index === 0 ? "qrc:/assets/icons/18/wrench.png"
                          : (index === 1 ? "qrc:/assets/icons/18/building.png"
                          : (index === 3 ? "qrc:/assets/icons/18/station.png" : "qrc:/assets/icons/18/triangle.png"))
                    color: "#8C9194"
                }

                Icon {
                    x: (parent.width - size) / 2
                    y: 6
                    size: 30
                    visible: parent.big
                    source: "qrc:/assets/icons/30/pin.png"
                    color: Theme.white
                }

                Text {
                    y: parent.big ? 40 : 26
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: index === 0 ? qsTr("Call mechanic")
                        : (index === 1 ? qsTr("Commute")
                        : (index === 2 ? qsTr("Explore")
                        : (index === 3 ? qsTr("Charging") : qsTr("Emergency"))))
                    color: parent.big ? Theme.white : "#7B8285"
                    font.family: Theme.fontFamily
                    font.pixelSize: parent.big ? 13 : 9
                }
            }
        }
    }
}
