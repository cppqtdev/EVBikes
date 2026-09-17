import QtQuick
import ClusterCore
import ClusterBackend
import ClusterComponents

// Screen composition (1280 x 480). Layers from back to front:
// shell -> bars -> stage content -> dock -> alerts -> telltales and status.
Item {
    id: shell

    property bool riding: Router.stage === Router.stageRide
    property bool alert: AlertData.popupVisible && riding
    property int alertKind: AlertData.kind
    property bool tyreAlert: alert && (alertKind === AlertData.LowTyreFront || alertKind === AlertData.LowTyreRear)
    property bool crashAlert: alert && alertKind === AlertData.CrashDetected
    property bool heatAlert: alert && (alertKind === AlertData.MotorOverheat || alertKind === AlertData.BatteryOverheat)
    property bool otherAlert: alert && !tyreAlert && !crashAlert && !heatAlert
    property bool fullAlert: crashAlert || heatAlert
    property bool hexStyle: SystemData.speedoStyle === SystemData.SpeedoHex
    property bool showBars: riding && !fullAlert && (!hexStyle || Router.menuOpen)
    property bool selfTestDone: false

    width: Theme.screenWidth
    height: Theme.screenHeight

    Timer {
        interval: 1500
        running: true
        onTriggered: shell.selfTestDone = true
    }

    ShellFrame {
        // The hues are the reference's, measured on the header light: cool grey
        // riding, white in sport, amber on the two full-screen alerts.
        //
        // The strengths are deliberately above it. The reference draws the eco
        // and normal header at about 25 levels, which is invisible on a black
        // panel, and only sport reads. The header has to separate itself in
        // every mode, so the cool one runs at roughly the reference's sport
        // level and sport is lifted further to stay ahead of it.
        housingLight: shell.fullAlert ? "#FF8020" : (Theme.sport ? "#FFFFFF" : "#DEE8FF")
        housingLightOpacity: shell.fullAlert ? 0.72 : (Theme.sport ? 0.95 : 0.62)
        glowStyle: !shell.riding ? (Router.stage === Router.stagePreRide ? 2 : 0) : (shell.fullAlert ? 2 : 1)
        glowColor: Router.stage === Router.stagePreRide ? (VehicleData.sideStandDown ? Theme.red : "#57F2C9") : Theme.glow
        showChannel: shell.showBars
        centerLift: shell.riding && shell.hexStyle && !Router.menuOpen ? 0.0 : 0.03
        floorColor: SystemData.authState === SystemData.AuthDenied ? Theme.red : Theme.teal
        floorOpacity: Router.stage === Router.stageAuth
                      ? (SystemData.authState === SystemData.AuthDenied ? 0.55
                        : (SystemData.authState === SystemData.AuthMatched ? 0.3 : 0.0))
                      : 0.0
    }

    PowerBar {
        visible: shell.showBars
        value: VehicleData.driveStale ? 0 : Math.abs(VehicleData.powerPercent)
    }

    RpmBar {
        visible: shell.showBars
        value: VehicleData.driveStale ? 0 : VehicleData.motorRpm / 100
        redZoneTop: true
    }

    SplashScreen {
        visible: Router.stage === Router.stageSplash
    }

    AuthScreen {
        visible: Router.stage === Router.stageAuth
    }

    PreRideScreen {
        visible: Router.stage === Router.stagePreRide
    }

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: shell.riding && !shell.fullAlert

        RideView {
            visible: !shell.hexStyle
        }

        HexSpeedoView {
            visible: shell.hexStyle && !Router.menuOpen && !Theme.alertMode
        }

        ProfilePage {}
        DigilockerPage {}
        SeatPage {}
        ChargingPage {}
        BikeStatusPage {}
        SecurityPage {}
        PaymentPage {}
        CustomizePage {}
        MiscPage {}

        MenuCarousel {
            y: 303
            visible: Router.menuOpen
        }

        BatteryTempBars {
            y: 363
        }

        BottomDock {
            y: 410
            mapActive: Router.centerView === Router.viewMap && !Router.menuOpen && !shell.hexStyle
            menuActive: Router.menuOpen
            focusIndex: Router.menuOpen ? -1 : Router.dockIndex
        }

        TyreAlertOverlay {
            visible: shell.tyreAlert
        }

        GenericAlertOverlay {
            visible: shell.otherAlert
        }

        CallScreen {}

        NotificationToast {
            x: 430
            y: 250
        }

        MenuLockHint {
            x: 470
            y: 262
        }
    }

    CrashOverlay {
        visible: shell.crashAlert
    }

    OverheatOverlay {
        visible: shell.heatAlert
    }

    StatusCorners {
        visible: shell.riding
    }

    TelltaleStrip {
        id: telltales
        selfTest: !shell.selfTestDone
    }
}
