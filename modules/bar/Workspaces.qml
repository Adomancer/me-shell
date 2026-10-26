import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.components
import qs.services
import qs.utils

// Workspace sebagai titik: kosong = cincin, berisi = titik redup, aktif = kapsul aksen yang meregang
// lalu menyusul saat pindah (ujung depan cepat, ujung belakang lambat). Tanpa kotak.
Item {
    id: root

    readonly property int slot: 18
    readonly property int dot: 6
    readonly property int count: Config.workspaces
    readonly property int activeIndex: Math.max(0, Math.min(count - 1, (Hyprland.focusedWorkspace?.id ?? 1) - 1))
    // Dua ujung indikator dengan kecepatan berbeda
    property real lead: activeIndex
    property real trail: activeIndex

    function occupied(i: int): bool {
        return Hyprland.workspaces.values.some(w => w.id === i + 1 && (w.toplevels?.values?.length ?? 1) > 0);
    }

    implicitWidth: slot * count
    implicitHeight: Config.barHeight - 10

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

    Repeater {
        model: root.count

        Item {
            id: cell

            required property int index
            readonly property bool isActive: index === root.activeIndex
            readonly property bool filled: root.occupied(index)
            // Ikon aplikasi window pertama di workspace ini (opsi barWorkspaceIcons)
            readonly property string appId: Config.barWorkspaceIcons ? (Hyprland.toplevels.values.find(t => t.workspace?.id === index + 1)?.wayland?.appId ?? "") : ""
            readonly property string appIcon: appId ? (DesktopEntries.heuristicLookup(appId)?.icon || "application-x-executable") : ""

            x: index * root.slot
            width: root.slot
            height: root.height

            // Kosong = cincin tipis, berisi = titik penuh redup
            Rectangle {
                anchors.centerIn: parent
                visible: cell.appIcon === ""
                width: root.dot
                height: root.dot
                radius: root.dot / 2
                color: cell.filled ? Appearance.colors.textDim : "transparent"
                border.width: cell.filled ? 0 : 1
                border.color: Appearance.colors.outline
            }

            AppIcon {
                anchors.centerIn: parent
                visible: cell.appIcon !== ""
                size: 14
                // Workspace kosong: jangan cari ikon sama sekali
                source: cell.appIcon ? Quickshell.iconPath(cell.appIcon, "application-x-executable") : ""
                lit: cell.isActive
                opacity: cell.isActive ? 1 : 0.6
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${cell.index + 1}`)
            }
        }
    }

    // Kapsul aktif: lebarnya mengikuti jarak dua ujung, jadi melar saat berpindah
    Rectangle {
        readonly property real from: Math.min(root.lead, root.trail)
        readonly property real to: Math.max(root.lead, root.trail)

        visible: !Config.barWorkspaceIcons
        anchors.verticalCenter: parent.verticalCenter
        x: from * root.slot + (root.slot - 14) / 2
        width: (to - from) * root.slot + 14
        height: root.dot + 2
        radius: height / 2
        color: Appearance.colors.primary
    }

    // Klik kanan = overview
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: DrawerState.toggle("overview")
    }

    WheelHandler {
        onWheel: event => Hyprland.dispatch(`workspace ${event.angleDelta.y > 0 ? "r-1" : "r+1"}`)
    }
}
