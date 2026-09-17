import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend

// Battery (left, fills from the left) and pack temperature (right, fills from the right).
Item {
    id: bars

    property int battery: VehicleData.batteryPercent
    property int temperature: VehicleData.packTempC
    property bool stale: VehicleData.batteryStale
    property int tempPercent: Math.max(0, Math.min(100, (temperature - 10) * 100 / 60))

    // Measured on the reference frames.
    readonly property color trackColor: "#383737"
    readonly property color chargeLow: bars.battery <= 15 ? "#B01E2E" : "#904229"
    readonly property color chargeHigh: bars.battery <= 15 ? "#E0A0A6" : "#969683"
    readonly property color tempCool: "#91C0A9"
    readonly property color tempHot: "#8F432B"
    readonly property int warmStart: 108
    readonly property int warmSteps: 8
    readonly property int warmStep: 11

    width: Theme.screenWidth
    height: 40

    Icon {
        x: 378
        y: 8
        size: 26
        source: "qrc:/assets/icons/26/battery_bolt.png"
        color: bars.stale ? Theme.textMuted : (bars.battery <= 15 ? Theme.red : "#77706E")
    }

    NumberReadout {
        id: batteryValue
        x: 404
        y: 0
        value: bars.battery
        stale: bars.stale
        fit: true
        pixelSize: 14
        widthFactor: 0.58
        italic: true
    }

    Text {
        x: batteryValue.x + batteryValue.width
        y: 2
        text: "%"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.italic: true
    }

    ColorizedImage {
        x: 398
        y: 20
        source: "qrc:/assets/cluster/bar_pointed_left.png"
        color: bars.trackColor
    }

    Item {
        id: charge

        x: 398
        y: 20
        width: bars.stale ? 0 : 190 * bars.battery / 100
        height: 12
        clip: true

        Behavior on width {
            NumberAnimation { duration: Theme.animSlow }
        }

        // Brick at the pointed end fading to pale at the fill edge, in clipped bands
        // because a horizontal Gradient is not available on this renderer.
        Repeater {
            model: 8

            Item {
                id: chargeBand

                readonly property real mix: (index + 0.5) / 8

                x: Math.floor(charge.width * index / 8)
                y: 0
                width: Math.ceil(charge.width / 8) + 1
                height: 12
                clip: true

                ColorizedImage {
                    x: -chargeBand.x
                    source: "qrc:/assets/cluster/bar_pointed_left.png"
                    color: Qt.rgba(bars.chargeLow.r + (bars.chargeHigh.r - bars.chargeLow.r) * chargeBand.mix,
                                   bars.chargeLow.g + (bars.chargeHigh.g - bars.chargeLow.g) * chargeBand.mix,
                                   bars.chargeLow.b + (bars.chargeHigh.b - bars.chargeLow.b) * chargeBand.mix, 1)
                }
            }
        }
    }

    NumberReadout {
        id: tempValue
        x: 852 - width
        y: -2
        value: bars.temperature
        stale: bars.stale
        fit: true
        pixelSize: 16
        widthFactor: 0.58
        italic: true
    }

    Text {
        x: 852
        y: 0
        text: "°c"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.italic: true
    }

    ColorizedImage {
        x: 684
        y: 20
        source: "qrc:/assets/cluster/bar_pointed_right.png"
        color: bars.trackColor
    }

    Item {
        id: heat

        readonly property int trackOrigin: width - 194

        x: 684 + 194 - width
        y: 20
        width: bars.stale ? 0 : 194 * bars.tempPercent / 100
        height: 12
        clip: true

        Behavior on width {
            NumberAnimation { duration: Theme.animSlow }
        }

        ColorizedImage {
            x: heat.trackOrigin
            source: "qrc:/assets/cluster/bar_pointed_right.png"
            color: bars.tempCool
        }

        // Fixed warm zone at the top of the scale, mint to brick in clipped bands.
        Repeater {
            model: bars.warmSteps

            Item {
                id: warmBand

                readonly property int offset: bars.warmStart + index * bars.warmStep
                readonly property real mix: (index + 1) / bars.warmSteps

                x: heat.trackOrigin + offset
                y: 0
                width: bars.warmStep + 1
                height: 12
                clip: true

                ColorizedImage {
                    x: -warmBand.offset
                    source: "qrc:/assets/cluster/bar_pointed_right.png"
                    color: Qt.rgba(bars.tempCool.r + (bars.tempHot.r - bars.tempCool.r) * warmBand.mix,
                                   bars.tempCool.g + (bars.tempHot.g - bars.tempCool.g) * warmBand.mix,
                                   bars.tempCool.b + (bars.tempHot.b - bars.tempCool.b) * warmBand.mix, 1)
                }
            }
        }

        ColorizedImage {
            x: heat.trackOrigin
            source: "qrc:/assets/cluster/ruler.png"
            color: "#FFFFFF"
            opacity: 0.6
        }
    }

    Icon {
        x: 878
        y: 8
        size: 28
        source: "qrc:/assets/icons/28/thermo.png"
        color: bars.stale ? Theme.textMuted : (bars.temperature >= 55 ? "#D9644A" : "#A7C9BA")
    }
}
