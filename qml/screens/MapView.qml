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
    // Past a kilometre, or a mile in miles, the turn distance is drawn as plain
    // text rather than counted down digit by digit.
    readonly property bool longWay: SystemData.useMiles
                                    ? NavigationData.distanceToManeuverM * Format.feetPerMetre >= Format.feetPerMile
                                    : NavigationData.distanceToManeuverM >= 1000

    readonly property font tileBigFont: Qt.font({ family: Theme.fontFamily, pixelSize: 13 })
    readonly property font tileFont: Qt.font({ family: Theme.fontFamily, pixelSize: 9 })

    readonly property int startX: 640
    readonly property int startY: 316
    //  Where the top of the road name lands. The fault row grows from the
    //  centre outwards and reaches x 764 by the fifth lamp, which is into the
    //  road name, so the guidance sits below the row rather than beside the
    //  buttons. The row's height never changes however many lamps are lit, so
    //  eight pixels under its bottom edge is clear for good.
    readonly property int guidanceTop: 92
    //  The buttons line up with the road name rather than with the clock, so
    //  the right-hand corner reads as one row. Four pixels above the text's
    //  own top, which centres a 30 high button on a 21 high line. The fault
    //  row never reaches them either: it stops at x 902 with every lamp lit
    //  and these start at 964.
    readonly property int buttonsY: map.guidanceTop - 4
    // Keep the pin above the endpoint, below the distance label (ends at y=147).
    readonly property int endY: 184

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

    //  Assigned, not bound: a Behavior on a bound property that other bindings
    //  read re-runs that binding on every read and the frame never finishes.
    property real routeLateral: 0
    property real routeNearness: 0
    onLateralChanged: map.routeLateral = map.lateral
    onNearnessChanged: map.routeNearness = map.nearness
    Component.onCompleted: {
        map.routeLateral = map.lateral
        map.routeNearness = map.nearness
    }

    Behavior on routeLateral {
        NumberAnimation {
            duration: Theme.animSlow
        }
    }

    Behavior on routeNearness {
        NumberAnimation {
            duration: Theme.animNormal
        }
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
                control1Y: map.startY - 150 * (1 - 0.55 * map.routeNearness)
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

    //  Right-hand corner, under the buttons, clear of the route line up the
    //  middle and short of the trip counter. The children of this box start
    //  66 down inside it, which is what the offset below takes off.
    Item {
        x: 140
        y: map.guidanceTop - 66
        width: Theme.screenWidth
        height: 170
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
            // Road names arrive from the phone and are absent from QML literals.
            // Keep coverage local to this 16px font, including the elision glyph.
            font: Qt.font({ family: Theme.fontFamily, pixelSize: 16,
                unicodeCoverage: [" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~…"] })
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

        // Under a kilometre (or a mile) the small unit counts down digit by
        // digit; above it the reading changes slowly enough to be plain text.
        NumberReadout {
            id: turnDistance
            digits: 4
            x: 620
            y: 88
            visible: !map.longWay
            value: SystemData.useMiles
                   ? Math.round(NavigationData.distanceToManeuverM * Format.feetPerMetre)
                   : NavigationData.distanceToManeuverM
            fit: true
            digitSize: 26
            digitFont: Qt.font({ family: Theme.fontFamily, pixelSize: 26 })
            widthFactor: 0.58
        }

        Text {
            x: turnDistance.x + turnDistance.width + 5
            y: 96
            visible: turnDistance.visible
            text: SystemData.useMiles ? qsTr("ft") : qsTr("m")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 17
        }

        Text {
            x: 620
            y: 92
            visible: map.longWay
            text: Format.distanceValue(NavigationData.distanceToManeuverM) + " "
                  + Format.distanceUnit(NavigationData.distanceToManeuverM)
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 26
        }

        //  Which exit to take, on the roundabout icon itself. The number is
        //  the part the rider needs; spelling the instruction out does not
        //  fit this corner and would elide away the one digit that matters.
        Rectangle {
            x: 606
            y: 90
            width: 18
            height: 18
            radius: 9
            visible: NavigationData.maneuver === NavigationData.RoundaboutEnter
            color: Theme.teal
        }

        Text {
            x: 606
            y: 92
            width: 18
            horizontalAlignment: Text.AlignHCenter
            visible: NavigationData.maneuver === NavigationData.RoundaboutEnter
            text: "" + NavigationData.roundaboutExit
            color: Theme.black
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        //  Arrival: how long and how far is left of the whole route, not of
        //  the next turn. Both arrive on every route update from the phone.
        Text {
            x: 560
            y: 124
            width: 162
            elide: Text.ElideRight
            visible: NavigationData.etaMinutes > 0 || NavigationData.distanceRemainingM > 0
            text: Format.etaText(NavigationData.etaMinutes) + "   "
                  + Format.distanceValue(NavigationData.distanceRemainingM) + " "
                  + Format.distanceUnit(NavigationData.distanceRemainingM)
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        //  Lane guidance. One bar per lane the road has, the ones to be in
        //  picked out. Eight is the width of the mask, and the model stays a
        //  constant so the delegates are laid out once at build time.
        Repeater {
            model: 8

            Rectangle {
                readonly property bool present: (NavigationData.laneMask & (1 << index)) !== 0
                readonly property bool wanted: (NavigationData.recommendedLaneMask & (1 << index)) !== 0

                x: 560 + index * 13
                y: 150
                width: 10
                height: 12
                radius: 2
                visible: present
                color: wanted ? Theme.teal : "#4A4A4A"
            }
        }

    }

    //  The map controls, level with the road name so the corner reads as one
    //  row. They are their own component because the hexagon layout carries
    //  them too.
    MapButtons {
        x: 964
        y: map.buttonsY
        visible: NavigationData.active
    }

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: !NavigationData.active

        Text {
            x: 0
            y: 110
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
                id: shortcut

                property bool big: index === 2

                x: index < 2 ? 494 + index * 52 : (index === 2 ? 598 : 674 + (index - 3) * 52)
                y: big ? 248 : 262
                width: big ? 70 : 48
                height: big ? 62 : 48

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: shortcut.big ? "#323232" : "#202020"
                    opacity: shortcut.big ? 1.0 : 0.8
                }

                Icon {
                    x: (parent.width - size) / 2
                    y: 5
                    size: 18
                    visible: !shortcut.big
                    source: index === 0 ? "qrc:/assets/icons/18/wrench.png"
                          : (index === 1 ? "qrc:/assets/icons/18/building.png"
                          : (index === 3 ? "qrc:/assets/icons/18/station.png" : "qrc:/assets/icons/18/triangle.png"))
                    color: "#8C9194"
                }

                Icon {
                    x: (parent.width - size) / 2
                    y: 6
                    size: 30
                    visible: shortcut.big
                    source: "qrc:/assets/icons/30/pin.png"
                    color: Theme.white
                }

                Text {
                    y: shortcut.big ? 40 : 26
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: index === 0 ? qsTr("Call mechanic")
                        : (index === 1 ? qsTr("Commute")
                        : (index === 2 ? qsTr("Explore")
                        : (index === 3 ? qsTr("Charging") : qsTr("Emergency"))))
                    color: shortcut.big ? Theme.white : "#7B8285"
                    font: shortcut.big ? map.tileBigFont : map.tileFont
                }
            }
        }
    }
}
