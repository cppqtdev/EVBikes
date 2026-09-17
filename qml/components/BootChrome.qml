import QtQuick
import QtQuickUltralite.Extras
import ClusterCore

// Fingerprint button and progress bar used during boot and login.
Item {
    id: chrome

    property real progress: 1.0
    property color printColor: "#5FD6B4"

    width: Theme.screenWidth
    height: Theme.screenHeight

    ColorizedImage {
        x: 602
        y: 295
        source: "qrc:/assets/cluster/fingerprint_disc.png"
        color: "#1D1D1D"
    }

    ColorizedImage {
        x: 602
        y: 295
        source: "qrc:/assets/cluster/fingerprint.png"
        color: chrome.printColor

        Behavior on color {
            ColorAnimation { duration: Theme.animNormal }
        }
    }

    ColorizedImage {
        x: 403
        y: 422
        source: "qrc:/assets/cluster/progress_glow.png"
        color: Theme.mint
        opacity: 0.45 * chrome.progress
    }

    // Measured on the reference: the track is a lit pill from x 415 to 862,
    // rows 435 to 448, and the fill runs to about 838 - the bar reads as
    // finished because the unfilled remainder keeps its bright outline, not
    // because the fill reaches the end.
    Rectangle {
        x: 415
        y: 435
        width: 448
        height: 14
        radius: 7
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#5F8E6F" }
            GradientStop { position: 1.0; color: "#7AB08D" }
        }
    }

    Rectangle {
        x: 418
        y: 438
        width: 442
        height: 8
        radius: 4
        color: "#132316"
    }

    Rectangle {
        x: 416
        y: 435
        width: Math.max(14, 446 * chrome.progress)
        height: 14
        radius: 7
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#91E4C3" }
            GradientStop { position: 1.0; color: "#7FF074" }
        }
    }
}
