import QtQuick
import ClusterCore
import ClusterBackend
import ClusterComponents

// Classic riding layout: speed, bike (or map), trip counter, range and odometer.
Item {
    id: ride

    property bool showDetails: !Router.menuOpen && !Theme.alertMode

    width: Theme.screenWidth
    height: Theme.screenHeight

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        opacity: ride.showDetails ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animNormal }
        }

        MapView {
            visible: Router.centerView === Router.viewMap
        }

        SpeedDigits {
            x: 4
            y: 99
        }

        BikeOrbit {
            x: 505
            y: 90
            visible: Router.centerView === Router.viewBike
        }

        TripCounter {
            x: 932
            y: 130
        }

        RangeOdoRow {
            y: 322
        }
    }
}
