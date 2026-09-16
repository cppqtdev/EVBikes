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
    property color shell: "#060708"
    property color housing: "#1E2123"
    property color housingBottom: "#151819"
    property color channel: "#010101"
    property color surface: "#1B1F21"
    property color surfaceRaised: "#262B2E"
    property color surfaceSelected: "#2C3134"
    property color stroke: "#3A4043"
    property color stroke2: "#5B6164"

    // Text
    property color textPrimary: SystemData.nightMode ? "#D5DCE0" : "#F4F6F6"
    property color textSecondary: SystemData.nightMode ? "#7E8A92" : "#A7AFB3"
    property color textMuted: "#5E666A"
    property color labelTeal: "#9FE3D0"
    property color digitGrey: "#D6D9DA"
    property color digitShade: "#A6E3D2"

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
    property color segLow: alertMode ? "#6A1018" : (sport ? "#8A2414" : "#2C7A66")
    property color segHigh: alertMode ? "#F02A3C" : (sport ? "#FF6A34" : "#B2FFE9")
    property color segTop: "#D3D8D6"
    property color segOff: "#3A3E40"
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
