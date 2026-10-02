import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// Alternative layout: battery column, hexagon speedometer and map.
Item {
    id: hex

    property int speed: VehicleData.speedKmh
    property int shownSpeed: Math.max(0, Math.min(999, Format.speedValue(speed)))

    width: Theme.screenWidth
    height: Theme.screenHeight

    ColorizedImage {
        x: 95; y: 108
        source: "qrc:/assets/cluster/trimmed/battery_edge_outer.png"
        color: "#3F9C80"
        opacity: 0.8
    }

    ColorizedImage {
        x: 143; y: 96
        source: "qrc:/assets/cluster/trimmed/battery_edge_inner.png"
        color: "#3A4A46"
        opacity: 0.8
    }

    BatteryColumn {
        percent: VehicleData.batteryPercent
    }

    ColorizedImage {
        x: 126; y: 109
        source: "qrc:/assets/cluster/trimmed/battery_tall_gloss.png"
        color: "#FFFFFF"
        opacity: 0.2
    }

    NumberReadout {
        id: socText
        digits: 3
        x: 223
        y: 186
        value: VehicleData.batteryPercent
        stale: VehicleData.batteryStale
        fit: true
        digitSize: 57
        digitFont: Qt.font({ family: Theme.fontFamily, pixelSize: 57, bold: true })
        widthFactor: 0.63
        color: "#A8F0D8"
    }

    Text {
        x: socText.x + socText.width + 4
        y: 222
        text: "%"
        color: "#A8F0D8"
        font.family: Theme.fontFamily
        font.pixelSize: 20
    }

    Text {
        x: 241
        y: 277
        width: 78
        height: 32
        text: qsTr("Range")
        color: "#C5AFA9"
        font.family: Theme.fontFamily
        font.pixelSize: 22
    }

    NumberReadout {
        id: rangeText
        digits: 5
        x: 320
        y: 267
        value: Format.distanceValueKm(VehicleData.rangeKm)
        stale: VehicleData.batteryStale
        fit: true
        digitSize: 32
        digitFont: Qt.font({ family: Theme.fontFamily, pixelSize: 32, bold: true })
        widthFactor: 0.65
        color: "#D8B3AA"
    }

    Text {
        x: rangeText.x + rangeText.width + 6
        y: 280
        text: SystemData.useMiles ? "mi" : "km"
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }

    ColorizedImage {
        x: 700
        y: 40
        source: "qrc:/assets/cluster/hex_terrain.png"
        color: "#4FD9B2"
        opacity: 0.6
    }

    ColorizedImage {
        x: 700
        y: 40
        source: Format.hexRouteImage(NavigationData.active, NavigationData.maneuver)
        color: Theme.white
    }

    ColorizedImage {
        x: 976
        y: 278
        source: "qrc:/assets/cluster/nav_cursor_small.png"
        color: Theme.white
    }

    ColorizedImage {
        x: 380
        y: 76
        source: "qrc:/assets/cluster/hex_backdrop.png"
        color: "#050506"
        opacity: 0.5
    }

    ColorizedImage {
        x: 540
        y: 265
        source: "qrc:/assets/images/glow_blob_200x90.png"
        color: Theme.teal
        opacity: 0.22
    }

    HexGauge {
        speed: hex.speed
        stale: VehicleData.driveStale
        miles: SystemData.useMiles
    }

    // Permanent cells: two visible digits below 100, optional hundreds.
    // The unit has its own line, clear of both the digits and gauge segments.
    Repeater {
        model: 3
        Text {
            x: 568 + index * 38
            y: 282
            width: 38
            height: 62
            visible: index > 0 || (!VehicleData.driveStale && hex.shownSpeed >= 100)
            text: VehicleData.driveStale ? "-" : Format.digitAt(hex.shownSpeed, 2 - index)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: 54
            color: VehicleData.driveStale ? Theme.textMuted : Theme.teal
        }
    }
    Text {
        x: 594
        y: 342
        width: 100
        height: 20
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Format.speedUnit()
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }

    // Compact guidance stays above the route and clear of the gauge labels.
    Rectangle {
        x: 866; y: 64; width: 260; height: 66
        radius: 6
        color: Theme.surfaceSunken
        visible: NavigationData.active
        Text {
            x: 14; y: 5; width: 232; height: 24
            text: NavigationData.roadName
            elide: Text.ElideRight
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }
        Icon {
            x: 14; y: 34; size: 24
            source: Format.turnIcon(NavigationData.maneuver)
            color: Theme.teal
            fillMode: Image.PreserveAspectFit
        }
        Text {
            x: 50; y: 31; width: 196; height: 30
            text: Format.distanceValue(NavigationData.distanceToManeuverM) + " "
                  + Format.distanceUnit(NavigationData.distanceToManeuverM)
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 22
        }
    }
    Text {
        x: 866; y: 80; width: 260; height: 48
        visible: !NavigationData.active
        text: PhoneData.connected ? qsTr("Start a route in the app") : qsTr("Connect phone for navigation")
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 930
        y: 400
        text: "RPM"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.italic: true
    }
}
