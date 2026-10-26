import Quickshell
import QtQuick
import qs.components
import qs.services
import qs.utils

// Popup notifikasi di pojok kanan atas. Hilang setelah Config.notifTimeout detik (ditahan saat di-hover).
Item {
    id: root

    // false = monitor ini tidak menampilkan popup
    property bool active: true
    readonly property int count: list.count

    implicitWidth: 380 + Appearance.padding.normal * 2
    implicitHeight: count > 0 ? list.contentHeight + Appearance.padding.normal * 2 : 0

    ListView {
        id: list

        x: Appearance.padding.normal
        y: Appearance.padding.normal
        width: 380
        height: contentHeight
        interactive: false
        spacing: Appearance.spacing.normal

        model: ScriptModel {
            values: root.active ? Notifs.popups : []
        }

        delegate: NotifCard {
            id: card

            required property var modelData
            required property int index

            width: ListView.view.width
            notif: modelData
            // Sudah di atas permukaan pojok; tanpa kotak kedua
            background: "transparent"
            progress: critical ? -1 : 1

            // Hitung mundur; berhenti selama kursor di atas kartu
            NumberAnimation on progress {
                running: !card.critical
                paused: card.hovered
                from: 1
                to: 0
                duration: Config.notifTimeout * 1000
                onFinished: Notifs.dismissPopup(card.modelData)
            }

            // Pemisah antar popup
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Appearance.padding.normal
                anchors.rightMargin: Appearance.padding.normal
                anchors.top: parent.bottom
                anchors.topMargin: list.spacing / 2
                visible: card.index < list.count - 1
                height: 1
                color: Appearance.colors.hairline
            }
        }

        add: Transition {
            Anim {
                property: "x"
                from: list.width
                to: 0
                duration: Appearance.anim.durations.expressiveDefault
                easing.bezierCurve: Appearance.anim.curves.expressiveDefault
            }
            Anim {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.anim.durations.small
            }
        }

        remove: Transition {
            Anim {
                property: "x"
                to: list.width
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
            Anim {
                property: "opacity"
                to: 0
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }

        displaced: Transition {
            Anim {
                property: "y"
                duration: Appearance.anim.durations.expressiveDefault
                easing.bezierCurve: Appearance.anim.curves.expressiveDefault
            }
            // Item yang tergeser di tengah animasi masuk langsung dirapikan
            Anim {
                property: "x"
                to: 0
            }
            Anim {
                property: "opacity"
                to: 1
            }
        }
    }
}
