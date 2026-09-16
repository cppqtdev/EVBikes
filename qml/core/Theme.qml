pragma Singleton
import QtQuick
import ClusterBackend

QtObject {
    id: theme

    // Screen: 1280 x 480 wide cluster (reference frames at 1280 px wide, y - 125)
    property int screenWidth: 1280
    property int screenHeight: 480

    // Brand palette
    property color black: "#000000"
    property color white: "#FEFEFE"
    property color teal: "#6FFFD8"
    property color orange: "#DE5013"

    // Surfaces
    property color shell: "#070709"
    property color housing: "#141414"
    property color housingBottom: "#141414"
    property color channel: "#010101"
    property color surface: "#191919"
    property color surfaceSunken: "#101010"
    property color surfaceRaised: "#242424"
    property color surfaceSelected: "#2A2A2A"
    property color stroke: "#3B3B3B"
    property color stroke2: "#5C5C5C"

    // Text
    property color textPrimary: SystemData.nightMode ? "#C8C8C8" : "#DEDEDE"
    property color textSecondary: SystemData.nightMode ? "#808080" : "#A8A8A8"
    property color textMuted: "#606060"
    property color labelTeal: "#8FB4AB"
    property color digitGrey: "#D9D9D9"
    property color digitShade: "#ADD5CB"
    property color digitUnit: "#C4D5D2"
    property color hexRing: "#9ED7C2"

    // Status colours
    property color red: "#E3263A"
    property color redDeep: "#5E0C14"
    property color amber: "#FFB020"
    property color green: "#3DDC84"
    property color mint: "#8CF5A8"
    property color blue: "#4FC3F7"
    property color goldTop: "#A48B57"
    property color goldBottom: "#5C4A2A"

    // Mode logic
    property bool sport: VehicleData.rideMode === VehicleData.Sport
    property bool alertMode: AlertData.popupVisible && AlertData.level >= AlertData.LevelWarning
    property bool critical: AlertData.level === AlertData.LevelCritical

    property color accent: alertMode ? red : (sport ? "#F0552E" : teal)
    property color glow: alertMode ? "#E8303F" : (sport ? "#E0402A" : "#57F2C9")

    // Bar segments
    property color segLow: alertMode ? "#6A1018" : (sport ? "#8A2414" : "#274337")
    property color segHigh: alertMode ? "#F02A3C" : (sport ? "#FF6A34" : "#B2FFE9")
    property color segTop: "#CDCDCD"
    property color segOff: "#3B3E3D"
    property color segRedZone: alertMode ? "#F02A3C" : "#B04A2C"
    property color segLabelOnLight: alertMode || sport ? "#D0452A" : "#2F9C80"

    // Telltales (ISO 2575 colour meaning)
    property color telltaleRed: "#F0303F"
    property color telltaleAmber: amber
    property color telltaleGreen: green
    property color telltaleBlue: "#3D8BFF"
    property color telltaleOff: "#8E9396"

    // Typography (Inter, SIL OFL)
    property string fontFamily: "Inter"
    property int fontSpeed: 150
    property int fontHuge: 44
    property int fontDisplay: 34
    property int fontTitle: 30
    property int fontHeading: 22
    property int fontBody: 18
    property int fontLabel: 16
    property int fontSmall: 14
    property int fontCaption: 12

    // Spacing, radius, motion
    property int spaceXs: 4
    property int spaceS: 8
    property int spaceM: 12
    property int spaceL: 16
    property int spaceXl: 24
    property int radiusS: 4
    property int radiusM: 8
    property int radiusL: 14

    property int animFast: 120
    property int animNormal: 240
    property int animSlow: 480

    // Safety rules
    property int menuLockSpeedKmh: 5
}
