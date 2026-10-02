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
    property bool selfTestDone: SystemData.uptimeMs >= 1500

    width: Theme.screenWidth
    height: Theme.screenHeight

    Rectangle {
        anchors.fill: parent
        color: Theme.black
        radius: 4
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

    // Keep the small boot pages static so Splash exists on the first frame.
    // Dynamic loading is reserved for the larger settings pages below.
    SplashScreen {
        visible: Router.stage === Router.stageSplash
    }

    AuthScreen {
        visible: Router.stage === Router.stageAuth
    }

    PreRideScreen {
        visible: Router.stage === Router.stagePreRide
    }

    // The ride dashboard contains many bindings to live CAN data. Do not
    // instantiate it while boot/auth/pre-ride screens are active; the first
    // CAN freshness update must not wake the entire hidden dashboard tree.
    Loader {
        active: shell.riding
        sourceComponent: rideContent
    }

    Component {
        id: rideContent

        Item {
            width: Theme.screenWidth
            height: Theme.screenHeight

            PowerBar {
                visible: shell.showBars
                value: VehicleData.driveStale ? 0 : Math.abs(VehicleData.powerPercent)
            }

            RpmBar {
                visible: shell.showBars
                value: VehicleData.driveStale ? 0 : VehicleData.motorRpm / 100
                redZoneTop: true
            }

            Item {
                width: Theme.screenWidth
                height: Theme.screenHeight
                visible: !shell.fullAlert

                Loader {
                    active: !shell.hexStyle && !Router.menuOpen && !Theme.alertMode
                    sourceComponent: classicRide
                }

                Loader {
                    active: shell.hexStyle && !Router.menuOpen && !Theme.alertMode
                    sourceComponent: hexRide
                }

        // Keep menu pages out of the initial scene. The Qt for MCUs desktop
        // platform shows its window after the first frame, and constructing
        // every settings page before that frame makes startup unnecessarily
        // expensive. Load only the page selected by the carousel, as in the
        // Crossware cluster.
                Loader {
                    active: Router.menuOpen
                    sourceComponent: Router.menuIndex === Router.menuProfile ? profilePage
                                   : Router.menuIndex === Router.menuDigilocker ? digilockerPage
                                   : Router.menuIndex === Router.menuSeat ? seatPage
                                   : Router.menuIndex === Router.menuCharging ? chargingPage
                                   : Router.menuIndex === Router.menuBikeStatus ? bikeStatusPage
                                   : Router.menuIndex === Router.menuSecurity ? securityPage
                                   : Router.menuIndex === Router.menuPayment ? paymentPage
                                   : Router.menuIndex === Router.menuCustomize ? customizePage
                                   : miscPage
                }

                Component { id: profilePage; ProfilePage {} }
                Component { id: digilockerPage; DigilockerPage {} }
                Component { id: seatPage; SeatPage {} }
                Component { id: chargingPage; ChargingPage {} }
                Component { id: bikeStatusPage; BikeStatusPage {} }
                Component { id: securityPage; SecurityPage {} }
                Component { id: paymentPage; PaymentPage {} }
                Component { id: customizePage; CustomizePage {} }
                Component { id: miscPage; MiscPage {} }
                Component { id: classicRide; RideView {} }
                Component { id: hexRide; HexSpeedoView {} }

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
            }
        }
    }

    TelltaleStrip {
        id: telltales
        selfTest: !shell.selfTestDone
    }
}
