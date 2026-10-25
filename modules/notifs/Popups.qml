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

            width: ListView.view.width
            notif: modelData
            background: Appearance.colors.surfaceContainerHigh

            HoverHandler {
                id: hover
            }

            Timer {
                interval: Config.notifTimeout * 1000
                running: !card.critical && !hover.hovered
                onTriggered: Notifs.dismissPopup(card.modelData)
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
