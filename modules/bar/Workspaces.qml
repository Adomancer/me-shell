import Quickshell.Hyprland
import QtQuick
import qs.components
import qs.utils

// Workspace ala end_4: workspace berisi window disambung jadi satu pita, indikator aktif
// meregang lalu menyusul saat pindah (ujung depan cepat, ujung belakang lambat).
StyledRect {
    id: root

    readonly property int slot: 26
    readonly property int count: Config.workspaces
    readonly property int activeIndex: Math.max(0, Math.min(count - 1, (Hyprland.focusedWorkspace?.id ?? 1) - 1))
    // Dua ujung indikator dengan kecepatan berbeda
    property real lead: activeIndex
    property real trail: activeIndex

    function occupied(i: int): bool {
        return Hyprland.workspaces.values.some(w => w.id === i + 1 && (w.toplevels?.values?.length ?? 1) > 0);
    }

    implicitWidth: slot * count + 4
    implicitHeight: slot + 4
    radius: height / 2
    color: Appearance.colors.surfaceContainer

    Behavior on lead {
        Anim {
            duration: Appearance.anim.durations.small
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }
    Behavior on trail {
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    // Pita workspace yang berisi window
    Repeater {
        model: root.count

        StyledRect {
            id: occ

            required property int index
            readonly property bool filled: root.occupied(index)
            readonly property bool joinLeft: filled && index > 0 && root.occupied(index - 1)
            readonly property bool joinRight: filled && index < root.count - 1 && root.occupied(index + 1)

            x: 2 + index * root.slot
            y: 2
            width: root.slot
            height: root.slot
            color: Appearance.colors.secondaryContainer
            opacity: filled ? 1 : 0
            topLeftRadius: joinLeft ? 0 : height / 2
            bottomLeftRadius: joinLeft ? 0 : height / 2
            topRightRadius: joinRight ? 0 : height / 2
            bottomRightRadius: joinRight ? 0 : height / 2

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }
        }
    }

    // Indikator aktif
    Rectangle {
        readonly property real from: Math.min(root.lead, root.trail)
        readonly property real to: Math.max(root.lead, root.trail)

        x: 2 + from * root.slot
        y: 2
        width: (to - from + 1) * root.slot
        height: root.slot
        radius: height / 2
        color: Appearance.colors.primary
    }

    Repeater {
        model: root.count

        Item {
            id: cell

            required property int index
            readonly property bool isActive: index === root.activeIndex
            readonly property bool filled: root.occupied(index)

            x: 2 + index * root.slot
            y: 2
            width: root.slot
            height: root.slot

            StyledText {
                anchors.centerIn: parent
                visible: cell.filled || cell.isActive
                text: cell.index + 1
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.smaller
                font.bold: cell.isActive
                color: cell.isActive ? Appearance.colors.primaryText : Appearance.colors.secondaryContainerText
            }

            Rectangle {
                anchors.centerIn: parent
                visible: !cell.filled && !cell.isActive
                width: 5
                height: 5
                radius: 3
                color: Appearance.colors.outline
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${cell.index + 1}`)
            }
        }
    }

    WheelHandler {
        onWheel: event => Hyprland.dispatch(`workspace ${event.angleDelta.y > 0 ? "r-1" : "r+1"}`)
    }
}
