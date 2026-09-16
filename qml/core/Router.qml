pragma Singleton
import QtQuick
import ClusterBackend

// UI state machine. Hardware state lives in the C++ singletons.
QtObject {
    id: router

    // Boot flow
    property int stageSplash: 0
    property int stageAuth: 1
    property int stagePreRide: 2
    property int stageRide: 3
    property int stage: stageSplash

    // Centre view while riding
    property int viewBike: 0
    property int viewMap: 1
    property int centerView: viewBike

    // Bottom dock focus while riding. Left and right walk it, OK acts on it.
    property int dockMap: 0
    property int dockMode: 1
    property int dockAlerts: 2
    property int dockSettings: 3
    property int dockCount: 4
    property int dockIndex: dockMode
    property bool alertsMuted: false

    // Menu carousel
    property bool menuOpen: false
    property int menuIndex: 1
    property int menuCount: 9
    property int subIndex: 0
    property int subLevel: 0

    property int menuProfile: 0
    property int menuDigilocker: 1
    property int menuSeat: 2
    property int menuCharging: 3
    property int menuBikeStatus: 4
    property int menuSecurity: 5
    property int menuPayment: 6
    property int menuCustomize: 7
    property int menuMisc: 8

    property bool menuAllowed: VehicleData.speedKmh <= Theme.menuLockSpeedKmh
    property bool paymentDone: false
    property int menuBlockedSeq: 0

    onMenuAllowedChanged: {
        if (!menuAllowed)
            closeMenu()
    }

    function menuTitle(index) {
        if (index === menuProfile) return qsTr("Profile")
        if (index === menuDigilocker) return qsTr("Digilocker")
        if (index === menuSeat) return qsTr("Seat")
        if (index === menuCharging) return qsTr("Charging")
        if (index === menuBikeStatus) return qsTr("Bike status")
        if (index === menuSecurity) return qsTr("Security")
        if (index === menuPayment) return qsTr("Payment")
        if (index === menuCustomize) return qsTr("Customize")
        if (index === menuMisc) return qsTr("Misc.")
        return ""
    }

    function wrap(index) {
        return (index + menuCount) % menuCount
    }

    function finishSplash() {
        if (stage === stageSplash)
            stage = stageAuth
    }

    function finishAuth() {
        if (stage === stageAuth)
            stage = stagePreRide
    }

    function finishPreRide() {
        if (stage === stagePreRide)
            stage = stageRide
    }

    function openMenu() {
        if (!menuAllowed) {
            menuBlockedSeq = menuBlockedSeq + 1
            return
        }
        subIndex = 0
        subLevel = 0
        paymentDone = false
        menuOpen = true
    }

    function closeMenu() {
        menuOpen = false
        subLevel = 0
    }

    function moveMenu(step) {
        menuIndex = wrap(menuIndex + step)
        subIndex = 0
        subLevel = 0
        paymentDone = false
    }

    function handleButton(button, action) {
        if (action === ClusterInput.LongPress && button === ClusterInput.Mode) {
            Simulator.nextScenario()
            return
        }
        if (AlertData.popupVisible) {
            handleAlertButton(button)
            return
        }
        if (stage === stageAuth) {
            handleAuthButton(button)
            return
        }
        if (stage === stagePreRide) {
            if (button === ClusterInput.Ok && !VehicleData.sideStandDown)
                finishPreRide()
            return
        }
        if (stage !== stageRide)
            return
        if (PhoneData.callStatus === PhoneData.Ringing) {
            if (button === ClusterInput.Ok)
                PhoneData.answerCall()
            else if (button === ClusterInput.Back)
                PhoneData.rejectCall()
            return
        }
        if (PhoneData.callStatus === PhoneData.Active) {
            if (button === ClusterInput.Back)
                PhoneData.rejectCall()
            return
        }
        if (menuOpen) {
            handleMenuButton(button)
            return
        }
        if (button === ClusterInput.Left)
            moveDock(-1)
        else if (button === ClusterInput.Right)
            moveDock(1)
        else if (button === ClusterInput.Up)
            SystemData.toggleSpeedoStyle()
        else if (button === ClusterInput.Mode)
            cycleRideMode()
        else if (button === ClusterInput.Ok)
            activateDock()
        else if (button === ClusterInput.Back)
            centerView = viewBike
    }

    function moveDock(step) {
        dockIndex = (dockIndex + step + dockCount) % dockCount
    }

    function activateDock() {
        if (dockIndex === dockMap)
            centerView = centerView === viewBike ? viewMap : viewBike
        else if (dockIndex === dockMode)
            cycleRideMode()
        else if (dockIndex === dockAlerts)
            alertsMuted = !alertsMuted
        else if (dockIndex === dockSettings)
            openMenu()
    }

    function cycleRideMode() {
        if (VehicleData.rideMode === VehicleData.Eco)
            VehicleData.rideMode = VehicleData.Normal
        else if (VehicleData.rideMode === VehicleData.Normal)
            VehicleData.rideMode = VehicleData.Sport
        else
            VehicleData.rideMode = VehicleData.Eco
    }

    function handleAlertButton(button) {
        if (AlertData.kind === AlertData.CrashDetected) {
            if (AlertData.phase === 1 && button === ClusterInput.Right)
                AlertData.cancelSos()
            return
        }
        if (AlertData.kind === AlertData.MotorOverheat || AlertData.kind === AlertData.BatteryOverheat) {
            if (AlertData.phase === 1) {
                if (button === ClusterInput.Up || button === ClusterInput.Down)
                    AlertData.protocolIndex = AlertData.protocolIndex === 0 ? 1 : 0
                else if (button === ClusterInput.Ok)
                    AlertData.activateProtocol()
            }
            return
        }
        if (button === ClusterInput.Ok)
            AlertData.acknowledge()
    }

    function handleAuthButton(button) {
        if (SystemData.authState === SystemData.AuthScanning)
            return
        if (button === ClusterInput.Left)
            SystemData.selectProfile(SystemData.profileIndex - 1)
        else if (button === ClusterInput.Right)
            SystemData.selectProfile(SystemData.profileIndex + 1)
        else if (button === ClusterInput.Ok)
            SystemData.startScan()
    }

    function handleMenuButton(button) {
        if (button === ClusterInput.Back) {
            if (subLevel > 0)
                subLevel = 0
            else
                closeMenu()
            return
        }
        if (button === ClusterInput.Left) {
            moveMenu(-1)
            return
        }
        if (button === ClusterInput.Right) {
            moveMenu(1)
            return
        }
        var up = button === ClusterInput.Up
        var down = button === ClusterInput.Down
        var ok = button === ClusterInput.Ok

        if (menuIndex === menuProfile) {
            if (up || down)
                SystemData.selectProfile(SystemData.profileIndex + (up ? -1 : 1))
        } else if (menuIndex === menuDigilocker) {
            if (up) subIndex = (subIndex + 2) % 3
            else if (down) subIndex = (subIndex + 1) % 3
        } else if (menuIndex === menuSeat) {
            if (up) SystemData.setSeatLevel(SystemData.seatLevel + 1)
            else if (down) SystemData.setSeatLevel(SystemData.seatLevel - 1)
            else if (ok) SystemData.setSeatLevel(2)
        } else if (menuIndex === menuCharging) {
            if (ok) SystemData.autoTurnOff = !SystemData.autoTurnOff
        } else if (menuIndex === menuBikeStatus) {
            if (ok) subLevel = subLevel === 0 ? 1 : 0
        } else if (menuIndex === menuSecurity) {
            if (up || down) subIndex = subIndex === 0 ? 1 : 0
            else if (ok && subIndex === 1) SystemData.antiTheftArmed = !SystemData.antiTheftArmed
            else if (ok && subIndex === 0) SystemData.clearTheftCaptures()
        } else if (menuIndex === menuPayment) {
            if (ok) paymentDone = true
        } else if (menuIndex === menuCustomize) {
            handleCustomizeButton(up, down, ok)
        } else if (menuIndex === menuMisc) {
            handleMiscButton(up, down, ok)
        }
    }

    // Misc: subIndex = tab (0 messages, 1 music, 2 reminders). On a list tab OK
    // steps into the rows (subLevel = 1 + row), where OK calls that contact.
    function handleMiscButton(up, down, ok) {
        if (subLevel === 0) {
            if (up) subIndex = (subIndex + 2) % 3
            else if (down) subIndex = (subIndex + 1) % 3
            else if (ok && subIndex === 1) PhoneData.mediaPlayPause()
            else if (ok) subLevel = 1
            return
        }
        var row = subLevel - 1
        if (up) subLevel = 1 + (row + 2) % 3
        else if (down) subLevel = 1 + (row + 1) % 3
        else if (ok && subIndex === 0) placeCall(row)
    }

    function placeCall(row) {
        PhoneData.callerName = Format.contactName(row)
        PhoneData.callStatus = PhoneData.Active
    }

    // Customize: subIndex = tab (0 help, 1 shortcut keys, 2 theme).
    // On the theme tab OK enters the list (subLevel = 1 + row).
    function handleCustomizeButton(up, down, ok) {
        if (subLevel === 0) {
            if (up) subIndex = (subIndex + 2) % 3
            else if (down) subIndex = (subIndex + 1) % 3
            else if (ok && subIndex === 2) subLevel = 1
            return
        }
        var row = subLevel - 1
        if (up) subLevel = 1 + (row + 4) % 5
        else if (down) subLevel = 1 + (row + 1) % 5
        else if (ok) activateThemeRow(row)
    }

    function activateThemeRow(row) {
        if (row === 0)
            SystemData.nightMode = !SystemData.nightMode
        else if (row === 1)
            SystemData.setBrightnessLevel(SystemData.brightness >= 100 ? 20 : SystemData.brightness + 20)
        else if (row === 2)
            SystemData.toggleClockFormat()
        else if (row === 3)
            SystemData.toggleSpeedoStyle()
        else if (row === 4)
            Simulator.running = !Simulator.running
    }
}
