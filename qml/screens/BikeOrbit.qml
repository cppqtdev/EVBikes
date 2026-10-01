import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterComponents

// Bike picture on its orbit ring with the small 360° handle.
Item {
    width: 270
    height: 120

    ColorizedImage {
        x: 10
        y: 68
        source: "qrc:/assets/cluster/orbit.png"
        color: "#C9CED0"
    }

    GlowSpot {
        x: 60
        y: 70
        color: Theme.accent
        opacity: 0.18
    }

    Image {
        x: 45
        y: -16
        source: "qrc:/assets/cluster/bike_180.png"
    }

    Rectangle {
        x: 194
        y: 98
        width: 14
        height: 14
        radius: 7
        color: "#E9ECED"

        Rectangle { x: 3; y: 5; width: 3; height: 3; radius: 1.5; color: "#1C1C1C" }
        Rectangle { x: 8; y: 5; width: 3; height: 3; radius: 1.5; color: "#1C1C1C" }
    }
}
