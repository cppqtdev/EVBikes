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
    //  digits is how many cells exist, not how many are drawn. Qt for MCUs
    //  pre-allocates a Repeater's delegates from a compile-time estimate, so
    //  the model must not change while it runs; fit moves the width instead.
    property int digits: 6
    // digitSize has to repeat the font's pixelSize: a font can be built but its
    // subproperties cannot be read back, and the cells are sized from it.
    property int digitSize: 24
    property font digitFont: Qt.font({ family: Theme.fontFamily, pixelSize: 24 })
    property color color: Theme.textPrimary
    property bool centered: false
    // stale means the reading stopped arriving. Showing the last figure would
    // claim the bike is still doing that, so the cells show dashes instead.
    property bool stale: false
    // fit lets the cell count follow the value, so a row keeps flowing and only
    // moves when a digit is gained or lost, never on every tick.
    property bool fit: false
    property real widthFactor: 0.62

    //  Keep this readout directly bound to its data. Animating every cell on
    //  each CAN update starves the QUL event loop when the live dashboard loads.
    readonly property int shownValue: value
    readonly property int cellWidth: Math.round(digitSize * widthFactor)
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
    readonly property int cells: digits
    //  How many of those cells carry something. The rest are the leading ones
    //  and stay empty, which is also what makes the row hug the number.
    readonly property int drawn: stale ? 2 : (fit ? used : digits)
    readonly property int blanks: Math.max(0, cells - drawn)
    readonly property color ink: stale ? Theme.textMuted : color

    width: drawn * cellWidth
    height: Math.round(digitSize * 1.25)

    Item {
        //  The width already counts only the drawn cells, so there is nothing
        //  left to pull back; centred readouts sit where their width puts them.
        x: 0
        width: readout.width
        height: readout.height

        Repeater {
            model: readout.cells

            Text {
                x: (index - readout.blanks) * readout.cellWidth
                width: readout.cellWidth
                height: readout.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: index < readout.blanks ? ""
                      : (readout.stale ? "-"
                         : Format.digitAt(readout.shownValue, readout.cells - 1 - index))
                color: readout.ink
                font: readout.digitFont
            }
        }
    }
}
