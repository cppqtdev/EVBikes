import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterComponents

// Boot animation: the bike front is drawn stroke by stroke, the headlight
// lights up, then the logo and the loading bar appear.
Item {
    id: splash

    property int step: 0
    property int strokes: 8

    width: Theme.screenWidth
    height: Theme.screenHeight

    Timer {
        interval: 220
        running: splash.visible && splash.step < 40
        repeat: true
        onTriggered: splash.step = splash.step + 1
    }

    onStepChanged: {
        if (step >= 26)
            Router.finishSplash()
    }

    Item {
        id: lineArt
        x: 637
        y: 100
        width: 360
        height: 270
        opacity: splash.step < 13 ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 600 }
        }

        Repeater {
            model: splash.strokes

            ColorizedImage {
                source: index === 0 ? "qrc:/assets/cluster/front_line_0.png"
                      : (index === 1 ? "qrc:/assets/cluster/front_line_1.png"
                      : (index === 2 ? "qrc:/assets/cluster/front_line_2.png"
                      : (index === 3 ? "qrc:/assets/cluster/front_line_3.png"
                      : (index === 4 ? "qrc:/assets/cluster/front_line_4.png"
                      : (index === 5 ? "qrc:/assets/cluster/front_line_5.png"
                      : (index === 6 ? "qrc:/assets/cluster/front_line_6.png"
                      : "qrc:/assets/cluster/front_line_7.png"))))))
                color: Theme.white
                opacity: splash.step > index ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
        }

        ColorizedImage {
            source: "qrc:/assets/cluster/front_headlight.png"
            color: Theme.white
            opacity: splash.step >= 9 ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 500 }
            }
        }
    }

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        opacity: splash.step >= 16 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }

        Text {
            x: 0
            y: 160
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: "EVBIKES"
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: 64
            font.letterSpacing: 6
        }

        BootChrome {
            progress: Math.min(0.95, Math.max(0.05, (splash.step - 16) / 9))
        }
    }
}
