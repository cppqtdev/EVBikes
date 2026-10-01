import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// Alternative layout: battery column, hexagon speedometer and map.
Item {
    id: hex

    property int speed: VehicleData.speedKmh
    property int shownSpeed: Format.speedValue(speed)

    width: Theme.screenWidth
    height: Theme.screenHeight

    ColorizedImage {
        source: "qrc:/assets/cluster/battery_edge_outer.png"
        color: "#3F9C80"
        opacity: 0.8
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/battery_edge_inner.png"
        color: "#3A4A46"
        opacity: 0.8
    }

    BatteryColumn {
        percent: VehicleData.batteryPercent
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/battery_tall_gloss.png"
        color: "#FFFFFF"
        opacity: 0.2
    }

    NumberReadout {
        id: socText
        x: 223
        y: 186
        value: VehicleData.batteryPercent
        stale: VehicleData.batteryStale
        fit: true
        pixelSize: 57
        widthFactor: 0.63
        color: "#A8F0D8"
        bold: true
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
        text: qsTr("Range:")
        color: "#C5AFA9"
        font.family: Theme.fontFamily
        font.pixelSize: 22
    }

    NumberReadout {
        x: 321
        y: 248
        value: Format.distanceValueKm(VehicleData.rangeKm)
        stale: VehicleData.batteryStale
        fit: true
        pixelSize: 48
        widthFactor: 0.55
        color: "#D8B3AA"
        bold: true
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
        source: Format.hexRouteImage(NavigationData.active ? NavigationData.maneuver : NavigationData.Straight)
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

    // Centred on 640 with a fixed 37 px cell per digit, the pitch measured on
    // the reference, so the reading counts without shifting under itself.
    DampedInt {
        id: speedDamper
        source: hex.shownSpeed
    }

    NumberReadout {
        x: 640 - width / 2
        y: 272
        value: speedDamper.value
        stale: VehicleData.driveStale
        digits: 3
        centered: true
        pixelSize: 64
        widthFactor: 0.58
        color: "#2EFED8"
    }

    Text {
        x: 683
        y: 304
        text: Format.speedUnitWord()
        color: "#5FE8BE"
        font.family: Theme.fontFamily
        font.pixelSize: 18
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
