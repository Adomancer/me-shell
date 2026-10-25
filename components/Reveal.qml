import QtQuick
import qs.utils

// Wadah animasi drawer. Ukurannya 0 saat tertutup, jadi otomatis keluar dari mask input.
Item {
    id: root

    property bool shown: false
    // "top": turun dari atas, "bottom": naik dari bawah, "center": efek layar CRT menyala
    property string edge: "top"
    property real openW: 0
    property real openH: 0
    default property alias content: holder.data

    readonly property bool crt: edge === "center"

    implicitWidth: crt ? holder.width * openW : holder.width
    implicitHeight: crt ? Math.max(holder.height * openH, openW > 0 ? 2 : 0) : holder.height * openH
    visible: openW > 0 || openH > 0
    clip: true

    Item {
        id: holder

        width: childrenRect.width
        height: childrenRect.height
        x: (root.width - width) / 2
        y: root.edge === "top" ? root.height - height : root.edge === "bottom" ? 0 : (root.height - height) / 2
        opacity: Math.min(1, root.openH * 1.5)
    }

    // Kilatan saat CRT menyala
    Rectangle {
        anchors.fill: parent
        visible: root.crt
        color: Appearance.colors.primary
        opacity: (1 - Math.min(1, root.openH)) * 0.8
    }

    states: State {
        name: "shown"
        when: root.shown

        PropertyChanges {
            target: root
            openW: 1
            openH: 1
        }
    }

    transitions: [
        Transition {
            to: "shown"

            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "openW"
                    duration: root.crt ? Appearance.anim.duration.fast : 0
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: root
                    property: "openH"
                    duration: Appearance.anim.duration.slow
                    easing.type: Appearance.anim.easing.emphasized
                }
            }
        },
        Transition {
            from: "shown"

            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "openH"
                    duration: Appearance.anim.duration.normal
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: root
                    property: "openW"
                    duration: root.crt ? Appearance.anim.duration.fast : 0
                }
            }
        }
    ]
}
