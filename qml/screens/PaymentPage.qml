import QtQuick
import ClusterCore
import ClusterBackend
import ClusterComponents

// Toll payment through the phone. Only allowed when stopped.
PageBase {
    id: page

    pageId: Router.menuPayment

    DemoNotice {
        subject: qsTr("Payments")
    }

    // Sample toll, no payment service behind it. Hidden outside demo mode
    // so a shipped cluster never shows a payment that cannot be made.
    Item {
        width: Theme.screenWidth
        height: 300
        visible: SystemData.demoMode

        Image {
            x: 565
            y: 72
            source: "qrc:/assets/cluster/payment_card.png"
        }

        Text {
            x: 520
            y: 180
            text: qsTr("Payment To :")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 15
        }

        Text {
            x: 616
            y: 180
            text: qsTr("Toll Naka Office")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 15
        }

        Rectangle {
            x: 520
            y: 204
            width: 250
            height: 1
            color: Theme.stroke2
        }

        GlassButton {
            x: 580
            y: 222
            width: 124
            height: 30
            fontSize: 14
            text: Router.paymentDone ? qsTr("PAID ✓") : qsTr("CONFIRM")
            selected: true
            glowColor: Router.paymentDone ? Theme.green : Theme.teal
        }
    }
}
