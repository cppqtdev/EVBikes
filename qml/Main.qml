import QtQuick
import ClusterCore
import ClusterBackend
import ClusterScreens

Rectangle {
    id: root

    width: Theme.screenWidth
    height: Theme.screenHeight
    color: Theme.black
    focus: true

    ClusterShell {}

    // Brightness and night mode, over everything.
    //
    // The cluster is drawn on black, so a black layer at opacity a scales every
    // lit pixel by 1 - a: a true dim, not a wash. On a board with a backlight
    // the panel does the dimming and only the night step is drawn here. A
    // critical alert takes the screen back to full brightness, because a crash
    // card at twenty per cent is no use to anybody.
    Rectangle {
        width: Theme.screenWidth
        height: Theme.screenHeight
        color: Theme.black
        visible: opacity > 0
        opacity: {
            if (AlertData.level === AlertData.LevelCritical)
                return 0.0
            var dim = SystemData.softwareDimming ? (100 - SystemData.brightness) * 0.0075 : 0.0
            if (SystemData.nightMode)
                dim = dim + 0.18
            return dim > 0.75 ? 0.75 : dim
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animNormal }
        }
    }

    Timer {
        interval: 50
        running: Simulator.running
        repeat: true
        onTriggered: Simulator.step(50)
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: SystemData.tick()
    }

    // Faster than the clock tick: a node that stops talking has to be noticed
    // within a few frames, not at the next second.
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: SystemData.poll()
    }

    Connections {
        target: ClusterInput
        function onButtonEvent(button: int, action: int) {
            Router.handleButton(button, action)
        }
    }

    // Desktop keyboard mapping; on the board the handlebar switch calls ClusterInput.inject().
    Keys.onPressed: {
        if (event.key === Qt.Key_Up) ClusterInput.inject(ClusterInput.Up, ClusterInput.Press)
        else if (event.key === Qt.Key_Down) ClusterInput.inject(ClusterInput.Down, ClusterInput.Press)
        else if (event.key === Qt.Key_Left) ClusterInput.inject(ClusterInput.Left, ClusterInput.Press)
        else if (event.key === Qt.Key_Right) ClusterInput.inject(ClusterInput.Right, ClusterInput.Press)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) ClusterInput.inject(ClusterInput.Ok, ClusterInput.Press)
        else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Escape) ClusterInput.inject(ClusterInput.Back, ClusterInput.Press)
        else if (event.key === Qt.Key_M) ClusterInput.inject(ClusterInput.Mode, ClusterInput.LongPress)
        else if (event.key === Qt.Key_P) Simulator.togglePark()
    }
}
