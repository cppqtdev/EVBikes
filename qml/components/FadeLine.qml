import QtQuick
import ClusterCore

// Thin horizontal line that fades out at both ends.
Rectangle {
    id: line

    property color lineColor: Theme.stroke2

    width: 280
    height: 1
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "#00000000" }
        GradientStop { position: 0.3; color: line.lineColor }
        GradientStop { position: 0.7; color: line.lineColor }
        GradientStop { position: 1.0; color: "#00000000" }
    }
}
