import QtQuick
import QtQuick.Shapes
import ClusterCore
import ClusterBackend
import ClusterComponents

// Summary cards; OK opens the last trip breakdown.
PageBase {
    id: page

    pageId: Router.menuBikeStatus

    // Rupees a petrol bike would have burnt over the same kilometre. An
    // assumption the cluster cannot measure, so it is named once here and both
    // the lifetime card and the trip card divide by the same figure. It wants
    // to become a setting the owner can correct for their own fuel price.
    property real petrolRupeesPerKm: 3
    property int co2GramsPerKm: 45
    property bool tripView: Router.subLevel === 1

    // Ride-mode split for the last trip, measured by TripData. The ring and the
    // caption both read these, so they cannot drift apart. Before the bike has
    // moved there is no split to draw, and an even third each says that more
    // honestly than a ring that claims a ride nobody took.
    property int ecoShare: TripData.recorded ? TripData.ecoShare : 34
    property int normalShare: TripData.recorded ? TripData.normalShare : 33
    property int sportShare: TripData.recorded ? TripData.sportShare : 33

    readonly property real ringRadius: 85
    readonly property real ringCx: 100
    readonly property real ringCy: 100

    // Twelve o'clock, going clockwise. One per cent is 3.6 degrees.
    readonly property real ringStart: -90
    readonly property real ecoEnd: ringStart + ecoShare * 3.6
    readonly property real normalEnd: ecoEnd + normalShare * 3.6
    readonly property real sportEnd: normalEnd + sportShare * 3.6

    function ringX(degrees) {
        return ringCx + ringRadius * Math.cos(degrees * Math.PI / 180)
    }

    function ringY(degrees) {
        return ringCy + ringRadius * Math.sin(degrees * Math.PI / 180)
    }

    Item {
        width: Theme.screenWidth
        height: 300
        visible: !page.tripView

        Text {
            x: 0
            y: 72
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("SUMMARY")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 18
        }

        StatCard {
            x: 423
            y: 118
            title: qsTr("Travelled:")
            value: VehicleData.odometerKm + " km"
            iconSource: "qrc:/assets/icons/36/route_loop.png"
        }

        StatCard {
            x: 666
            y: 118
            title: qsTr("Fuel savings:")
            value: Math.round(VehicleData.odometerKm * page.petrolRupeesPerKm) + " Rs"
            iconSource: "qrc:/assets/icons/36/fuel_can.png"
        }

        StatCard {
            x: 423
            y: 206
            title: qsTr("Carbon savings:")
            value: Math.max(1, Math.floor(VehicleData.odometerKm / 4000)) + qsTr(" trees planted")
            iconSource: "qrc:/assets/icons/36/sprout.png"
        }

        StatCard {
            x: 666
            y: 206
            title: qsTr("CO2 saved:")
            value: Math.round(VehicleData.odometerKm * page.co2GramsPerKm / 100000) + " Kg"
            iconSource: "qrc:/assets/icons/36/cloud.png"
        }
    }

    Item {
        width: Theme.screenWidth
        height: 300
        visible: page.tripView

        Rectangle {
            x: 363
            y: 68
            width: 567
            height: 280
            radius: 4
            color: "#181818"
            opacity: 0.95
        }

        Text {
            x: 0
            y: 82
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Last ride  ›")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.bold: true
        }

        Shape {
            x: 541
            y: 108
            width: 200
            height: 200

            ShapePath {
                strokeColor: "#12402F"
                strokeWidth: 20
                fillColor: "transparent"
                startX: 100
                startY: 15
                PathArc { x: 100; y: 185; radiusX: 85; radiusY: 85 }
                PathArc { x: 100; y: 15; radiusX: 85; radiusY: 85 }
            }

            // Each wedge is drawn as two half-sweeps. A single arc over 180
            // degrees needs useLargeArc, which is where the ring came apart,
            // and its endpoints were literal coordinates that no longer
            // matched the percentages beside it.
            ShapePath {
                strokeColor: "#2FE07F"
                strokeWidth: 18
                capStyle: ShapePath.FlatCap
                fillColor: "transparent"
                startX: page.ringX(page.ringStart)
                startY: page.ringY(page.ringStart)

                PathArc {
                    x: page.ringX((page.ringStart + page.ecoEnd) / 2)
                    y: page.ringY((page.ringStart + page.ecoEnd) / 2)
                    radiusX: page.ringRadius
                    radiusY: page.ringRadius
                }

                PathArc {
                    x: page.ringX(page.ecoEnd)
                    y: page.ringY(page.ecoEnd)
                    radiusX: page.ringRadius
                    radiusY: page.ringRadius
                }
            }

            ShapePath {
                strokeColor: "#D9B561"
                strokeWidth: 18
                capStyle: ShapePath.FlatCap
                fillColor: "transparent"
                startX: page.ringX(page.ecoEnd)
                startY: page.ringY(page.ecoEnd)

                PathArc {
                    x: page.ringX((page.ecoEnd + page.normalEnd) / 2)
                    y: page.ringY((page.ecoEnd + page.normalEnd) / 2)
                    radiusX: page.ringRadius
                    radiusY: page.ringRadius
                }

                PathArc {
                    x: page.ringX(page.normalEnd)
                    y: page.ringY(page.normalEnd)
                    radiusX: page.ringRadius
                    radiusY: page.ringRadius
                }
            }

            ShapePath {
                strokeColor: "#D34A3E"
                strokeWidth: 18
                capStyle: ShapePath.FlatCap
                fillColor: "transparent"
                startX: page.ringX(page.normalEnd)
                startY: page.ringY(page.normalEnd)

                PathArc {
                    x: page.ringX((page.normalEnd + page.sportEnd) / 2)
                    y: page.ringY((page.normalEnd + page.sportEnd) / 2)
                    radiusX: page.ringRadius
                    radiusY: page.ringRadius
                }

                PathArc {
                    x: page.ringX(page.sportEnd)
                    y: page.ringY(page.sportEnd)
                    radiusX: page.ringRadius
                    radiusY: page.ringRadius
                }
            }
        }

        Text {
            x: 541
            y: 172
            width: 200
            horizontalAlignment: Text.AlignHCenter
            text: page.ecoShare + qsTr("% Eco") + "\n"
                  + page.normalShare + qsTr("% Normal") + "\n"
                  + page.sportShare + qsTr("% Sport")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 18
        }

        TripStat {
            x: 382
            y: 128
            title: qsTr("Ride time:")
            value: TripData.recorded ? TripData.rideMinutes + qsTr(" mins") : "--"
        }

        TripStat {
            x: 750
            y: 128
            title: qsTr("Distance:")
            value: Format.tenths(VehicleData.tripKmX10) + " km"
        }

        TripStat {
            x: 382
            y: 254
            title: qsTr("Fuel savings:")
            value: TripData.recorded
                   ? Math.round(VehicleData.tripKmX10 * page.petrolRupeesPerKm / 10) + " Rs"
                   : "--"
        }

        TripStat {
            x: 750
            y: 254
            title: qsTr("SOC consumed:")
            value: TripData.recorded ? TripData.socUsedPercent + " %" : "--"
        }

        Rectangle {
            x: 612
            y: 312
            width: 56
            height: 56
            radius: 28
            color: "#202020"
        }

        Icon {
            x: 626
            y: 326
            size: 28
            source: "qrc:/assets/icons/28/back_curve.png"
            color: Theme.textPrimary
        }
    }
}
