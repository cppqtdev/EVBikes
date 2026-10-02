import QtQuick
import ClusterCore
import ClusterBackend
import ClusterScreens

Rectangle {
    id: root

    width: Theme.screenWidth
    height: Theme.screenHeight
    color: Theme.black

    Component.onCompleted: root.forceActiveFocus()

    ClusterShell {}
    PerformanceOverlay {
        x: 4
        y: root.height - height - 4
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
        else if (event.key === Qt.Key_F12) SystemData.showPerformance = !SystemData.showPerformance
        else if (event.key === Qt.Key_P) Simulator.togglePark()
    }
}
