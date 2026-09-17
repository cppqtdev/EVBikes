import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// Other warnings: low battery, ABS fault, side stand, system fault.
Item {
    width: Theme.screenWidth
    height: Theme.screenHeight

    ColorizedImage {
        x: 360
        y: 68
        source: "qrc:/assets/cluster/card_mid.png"
        color: "#161819"
        opacity: 0.94
    }

    ColorizedImage {
        x: 360
        y: 68
        source: "qrc:/assets/cluster/card_mid_edge.png"
        color: "#8E9396"
        opacity: 0.5
    }

    Ribbon {
        x: 470
        y: 84
        text: AlertData.level === AlertData.LevelCritical ? qsTr("WARNING") : qsTr("ALERT")
    }

    Icon {
        x: 604
        y: 130
        size: 72
        source: Format.alertIcon(AlertData.kind)
        color: AlertData.level === AlertData.LevelCritical ? Theme.red : Theme.amber
    }

    Text {
        x: 0
        y: 214
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        text: Format.alertTitle(AlertData.kind)
        color: AlertData.level === AlertData.LevelCritical ? Theme.red : Theme.amber
        font.family: Theme.fontFamily
        font.pixelSize: 28
        font.bold: true
        font.italic: true
    }

    Text {
        x: 0
        y: 254
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        text: Format.alertAdvice(AlertData.kind)
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 18
    }

    Text {
        x: 0
        y: 310
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        visible: AlertData.level !== AlertData.LevelCritical
        text: qsTr("OK to dismiss")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
}
