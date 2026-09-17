import QtQuick
import ClusterCore

// A live number that neither jumps nor flickers.
//
// Two things cause the flicker. A plain Text bound to a value re-lays out on
// every change, and proportional digits are different widths, so the row
// shifts sideways as the number counts. And the raw value steps in whole
// units, so the reading snaps instead of moving. Here each digit sits in its
// own fixed cell, and the displayed value is animated towards the real one.
Item {
    id: readout

    property int value: 0
    property int digits: 2
    property int pixelSize: 24
    property color color: Theme.textPrimary
    property bool bold: false
    property bool italic: false
    property bool centered: false
    // stale means the reading stopped arriving. Showing the last figure would
    // claim the bike is still doing that, so the cells show dashes instead.
    property bool stale: false
    // fit lets the cell count follow the value, so a row keeps flowing and only
    // moves when a digit is gained or lost, never on every tick.
    property bool fit: false
    property int duration: Theme.animNormal
    property real widthFactor: 0.62

    property real shown: value

    readonly property int shownValue: Math.round(shown)
    readonly property int cellWidth: Math.round(pixelSize * widthFactor)
    // Digit count by arithmetic: String.length is not part of the JavaScript
    // subset Qt for MCUs provides.
    readonly property int used: {
        var rest = Math.abs(shownValue)
        var count = 1
        while (rest >= 10) {
            rest = Math.floor(rest / 10)
            count = count + 1
        }
        return count
    }
    readonly property int cells: stale ? (fit ? 2 : digits) : (fit ? used : digits)
    readonly property int blanks: stale ? 0 : Math.max(0, cells - used)
    readonly property color ink: stale ? Theme.textMuted : color

    width: cells * cellWidth
    height: Math.round(pixelSize * 1.25)

    Behavior on shown {
        NumberAnimation { duration: readout.duration }
    }

    Item {
        // Leading cells are blank, so centring means pulling the drawn digits
        // back over half of them.
        x: readout.centered ? -readout.blanks * readout.cellWidth / 2 : 0
        width: readout.width
        height: readout.height

        Repeater {
            model: readout.cells

            Text {
                x: index * readout.cellWidth
                width: readout.cellWidth
                height: readout.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: readout.stale ? "-"
                      : (index < readout.blanks ? "" : Format.digitAt(readout.shownValue, readout.cells - 1 - index))
                color: readout.ink
                font.family: Theme.fontFamily
                font.pixelSize: readout.pixelSize
                font.bold: readout.bold
                font.italic: readout.italic
            }
        }
    }
}
