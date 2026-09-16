import QtQuick
import QtQuickUltralite.Extras
import ClusterCore

// Fingerprint button and progress bar used during boot and login.
Item {
    id: chrome

    property real progress: 0.95
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

    Rectangle {
        x: 414
        y: 434
        width: 449
        height: 16
        radius: 8
        color: "#1E3A2A"
    }

    Rectangle {
        x: 415
        y: 435
        width: 447
        height: 14
        radius: 7
        color: "#0D0D0D"
    }

    Rectangle {
        x: 417
        y: 437
        width: Math.max(10, 443 * chrome.progress)
        height: 10
        radius: 5
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#A8FFC0" }
            GradientStop { position: 1.0; color: "#6ADF8A" }
        }
    }
}
