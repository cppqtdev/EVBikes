import QtQuick
import ClusterCore
import ClusterBackend
import ClusterComponents

// Tabs: help, shortcut keys (handlebar map), theme (settings list).
PageBase {
    id: page

    pageId: Router.menuCustomize

    property int tab: Router.subIndex
    property int row: Router.subLevel - 1

    TabStrip {
        x: 505
        y: 80
        first: qsTr("help")
        second: qsTr("Shortcut keys")
        third: qsTr("theme")
        current: page.tab
    }

    Item {
        width: Theme.screenWidth
        height: 300
        visible: page.tab === 0

        Text {
            x: 440
            y: 132
            width: 400
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: qsTr("← → move between menu items\n↑ ↓ change the value on a page\nOK select   ·   BACK close the menu")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 17
        }
    }

    Item {
        width: Theme.screenWidth
        height: 300
        visible: page.tab === 1

        Rectangle {
            x: 343
            y: 158
            width: 42
            height: 108
            radius: 3
            color: "#2D2D2D"
        }

        Icon { x: 352; y: 162; size: 24; source: "qrc:/assets/icons/24/low_beam.png"; color: "#C3C8CA" }

        Rectangle { x: 343; y: 194; width: 42; height: 36; color: "#3E3E3E" }

        Text {
            x: 343
            y: 202
            width: 42
            horizontalAlignment: Text.AlignHCenter
            text: "ATO"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Icon { x: 352; y: 238; size: 24; source: "qrc:/assets/icons/24/high_beam.png"; color: "#C3C8CA" }

        Rectangle {
            x: 425
            y: 148
            width: 200
            height: 96
            radius: 10
            color: "#2D2D2D"
            transform: Rotation { origin.x: 100; origin.y: 48; angle: -8 }
        }

        Icon { x: 462; y: 176; size: 26; source: "qrc:/assets/icons/26/chevron.png"; color: "#C3C8CA" }
        Icon { x: 452; y: 206; size: 26; source: "qrc:/assets/icons/26/back.png"; color: "#C3C8CA" }

        Text {
            x: 500
            y: 170
            text: "- - - - - - - - - -"
            color: "#C3C8CA"
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }

        Text {
            x: 496
            y: 206
            text: "- - - - - - - - - -"
            color: "#C3C8CA"
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }

        Rectangle {
            x: 662
            y: 148
            width: 200
            height: 96
            radius: 10
            color: "#2D2D2D"
            transform: Rotation { origin.x: 100; origin.y: 48; angle: 8 }
        }

        Text { x: 692; y: 160; text: "S"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14 }
        Text { x: 732; y: 168; text: "N"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14 }
        Text { x: 768; y: 176; text: "E"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14 }
        Icon { x: 688; y: 192; size: 18; source: "qrc:/assets/icons/18/back.png"; color: Theme.textPrimary }
        Text { x: 727; y: 190; text: "+"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26 }
        Icon { x: 764; y: 206; size: 20; source: "qrc:/assets/icons/20/play.png"; color: Theme.textPrimary }
        Icon { x: 796; y: 180; size: 18; source: "qrc:/assets/icons/18/wrench.png"; color: Theme.textPrimary }
        Icon { x: 798; y: 210; size: 18; source: "qrc:/assets/icons/18/grid_plus.png"; color: Theme.textPrimary }

        Rectangle {
            x: 902
            y: 158
            width: 42
            height: 108
            radius: 3
            color: "#2D2D2D"
        }

        Icon { x: 911; y: 162; size: 24; source: "qrc:/assets/icons/24/joystick.png"; color: "#8C9194" }

        Rectangle { x: 902; y: 194; width: 42; height: 42; color: "#3E3E3E" }

        Icon { x: 910; y: 199; size: 26; source: "qrc:/assets/icons/26/power.png"; color: Theme.textPrimary }

        Text {
            x: 902
            y: 240
            width: 42
            horizontalAlignment: Text.AlignHCenter
            text: "C"
            color: "#8C9194"
            font.family: Theme.fontFamily
            font.pixelSize: 18
        }

        Rectangle {
            x: 620
            y: 252
            width: 48
            height: 26
            radius: 3
            color: "#2D2D2D"
        }

        Icon { x: 634; y: 255; size: 20; source: "qrc:/assets/icons/20/back_curve.png"; color: Theme.textPrimary }
    }

    Column {
        x: 400
        y: 120
        spacing: 0
        visible: page.tab === 2

        MenuRow {
            height: 35
            title: qsTr("Theme")
            value: SystemData.nightMode ? qsTr("Night") : qsTr("Day")
            iconSource: "qrc:/assets/icons/24/sun.png"
            selected: page.row === 0
        }

        MenuRow {
            height: 35
            title: qsTr("Brightness")
            value: SystemData.brightness + "%"
            iconSource: "qrc:/assets/icons/24/sun.png"
            selected: page.row === 1
        }

        MenuRow {
            height: 35
            title: qsTr("Clock format")
            value: SystemData.use24Hour ? "24 h" : "12 h"
            iconSource: "qrc:/assets/icons/24/clock.png"
            selected: page.row === 2
        }

        MenuRow {
            height: 35
            title: qsTr("Speedometer style")
            value: SystemData.speedoStyle === SystemData.SpeedoHex ? qsTr("Hexagon") : qsTr("Classic")
            iconSource: "qrc:/assets/icons/24/compass.png"
            selected: page.row === 3
        }

        MenuRow {
            height: 35
            title: qsTr("Demo mode")
            value: Simulator.running ? qsTr("On") : qsTr("Off")
            iconSource: "qrc:/assets/icons/24/info.png"
            selected: page.row === 4
        }
    }
}
