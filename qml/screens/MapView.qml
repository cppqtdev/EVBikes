import QtQuick
import QtQuick.Shapes
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

    // The route is drawn, not picked from a set of pictures, so it can move
    // while the trip runs. Lateral says which way the road goes; nearness is
    // how close the turn is, and pulls the bend down towards the rider.
    readonly property int startX: 640
    readonly property int startY: 316
    readonly property int endY: 112

    readonly property int lateral: {
        var m = NavigationData.maneuver
        if (m === NavigationData.SlightLeft || m === NavigationData.ForkLeft || m === NavigationData.MergeLeft)
            return -90
        if (m === NavigationData.SlightRight || m === NavigationData.ForkRight || m === NavigationData.MergeRight)
            return 90
        if (m === NavigationData.Left) return -190
        if (m === NavigationData.Right) return 190
        if (m === NavigationData.SharpLeft) return -250
        if (m === NavigationData.SharpRight) return 250
        if (m === NavigationData.UTurnLeft) return -270
        if (m === NavigationData.UTurnRight) return 270
        if (m === NavigationData.RoundaboutEnter || m === NavigationData.RoundaboutExit) return 150
        return 0
    }

    readonly property real nearness: Math.max(0, Math.min(1, 1 - NavigationData.distanceToManeuverM / 800))

    property real routeLateral: map.lateral
    property real routeNearness: map.nearness

    Behavior on routeLateral {
        NumberAnimation { duration: Theme.animSlow }
    }

    Behavior on routeNearness {
        NumberAnimation { duration: Theme.animNormal }
    }

    Shape {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: NavigationData.active

        ShapePath {
            strokeColor: Theme.white
            strokeWidth: 3
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: map.startX
            startY: map.startY

            PathCubic {
                x: map.startX + map.routeLateral
                y: map.endY
                control1X: map.startX
                control1Y: map.startY - 200 * (1 - 0.55 * map.routeNearness)
                control2X: map.startX + map.routeLateral
                control2Y: map.endY + 80
            }
        }
    }

    ColorizedImage {
        x: map.startX + map.routeLateral - 11
        y: map.endY - 26
        source: "qrc:/assets/icons/30/pin.png"
        color: Theme.white
        visible: NavigationData.active
    }

    ColorizedImage {
        x: 616
        y: 295
        source: "qrc:/assets/cluster/nav_cursor.png"
        color: Theme.white

        // The rider turns into the bend as it arrives, the way a real heading
        // marker swings before the junction.
        transform: Rotation {
            origin.x: 24
            origin.y: 24
            angle: map.routeLateral * map.routeNearness * 0.05
        }
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

        // Under a kilometre the metres count down digit by digit; above it the
        // reading changes slowly enough to be plain text.
        NumberReadout {
            id: turnDistance
            x: 620
            y: 88
            visible: NavigationData.distanceToManeuverM < 1000
            value: NavigationData.distanceToManeuverM
            fit: true
            pixelSize: 26
            widthFactor: 0.58
        }

        Text {
            x: turnDistance.x + turnDistance.width + 5
            y: 96
            visible: turnDistance.visible
            text: qsTr("m")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 17
        }

        Text {
            x: 620
            y: 92
            visible: NavigationData.distanceToManeuverM >= 1000
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
