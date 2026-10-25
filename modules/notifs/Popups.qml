import Quickshell
import QtQuick
import qs.services
import qs.utils

// Popup notifikasi di kanan atas. Hilang setelah 5 detik (ditahan saat di-hover).
ListView {
    id: root

    // false = monitor ini tidak menampilkan popup
    property bool active: true

    width: 360
    implicitHeight: contentHeight
    interactive: false
    spacing: Appearance.spacing.normal

    model: ScriptModel {
        values: root.active ? Notifs.popups : []
    }

    delegate: NotifCard {
        id: card

        required property var modelData

        width: root.width
        notif: modelData

        HoverHandler {
            id: hover
        }

        Timer {
            interval: 5000
            running: !card.critical && !hover.hovered
            onTriggered: Notifs.dismissPopup(card.modelData)
        }
    }

    add: Transition {
        NumberAnimation {
            property: "x"
            from: root.width
            to: 0
            duration: Appearance.anim.duration.slow
            easing.type: Appearance.anim.easing.emphasized
        }
    }

    remove: Transition {
        NumberAnimation {
            property: "opacity"
            to: 0
            duration: Appearance.anim.duration.fast
        }
    }

    displaced: Transition {
        NumberAnimation {
            property: "y"
            duration: Appearance.anim.duration.normal
            easing.type: Appearance.anim.easing.standard
        }
    }
}
