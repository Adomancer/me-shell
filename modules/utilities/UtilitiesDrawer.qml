import QtQuick
import qs.components
import qs.services
import qs.utils

// Isi drawer pojok kanan bawah: tumpukan toast, lalu panel utilitas saat dibuka.
// Ukurannya ikut isi, jadi drawer melar halus saat toast datang atau panel dibuka.
Item {
    id: root

    property bool open: false
    readonly property int pad: Appearance.padding.large
    readonly property int innerWidth: open ? panel.pageWidth : toasts.implicitWidth
    readonly property real panelHeight: open ? panel.implicitHeight : 0
    readonly property real gap: open && toasts.count > 0 ? Appearance.spacing.large : 0

    implicitWidth: innerWidth + pad * 2
    implicitHeight: toasts.implicitHeight + gap + panelHeight + pad * 2

    ToastList {
        id: toasts

        x: root.pad
        y: root.pad
        width: root.innerWidth
    }

    UtilitiesPanel {
        id: panel

        x: root.pad
        y: root.pad + toasts.implicitHeight + root.gap
        width: root.innerWidth
        shown: root.open
        opacity: root.open ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.small
            }
        }
    }
}
