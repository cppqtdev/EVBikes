import QtQuick
import ClusterCore

// Horizontal colour band that fades out to both sides (behind titles).
Rectangle {
    id: band

    property color bandColor: Theme.red

    width: 320
    height: 26
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "#00000000" }
        GradientStop { position: 0.5; color: band.bandColor }
        GradientStop { position: 1.0; color: "#00000000" }
    }
}
