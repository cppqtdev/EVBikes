import QtQuick
import QtQuickUltralite.Extras

// The small tinted glow, at the one size the artwork is drawn at.
//
// It lives here because Qt for MCUs pulls an image into the resource set of
// the module whose QML names it, and refuses to merge the same image from two
// sets. Only one module may name a given file, so the file has one component.
ColorizedImage {
    width: 150
    height: 40
    source: "qrc:/assets/images/glow_blob_150x40.png"
}
