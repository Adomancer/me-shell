import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import qs.components
import qs.services
import qs.utils

// Overview workspace: tiap workspace digambar sebagai layar mini berisi pratinjau live window-nya.
// Klik window = fokus, klik workspace = pindah ke sana, seret window ke workspace lain = pindahkan.
Item {
    id: root

    property bool shown: false
    // Ukuran layar (logical) untuk perbandingan skala kartu
    property real screenWidth: 1920
    property real screenHeight: 1080

    readonly property int count: Config.workspaces
    readonly property int columns: Math.min(count, 5)
    readonly property int rows: Math.ceil(count / columns)
    readonly property int gap: Appearance.spacing.normal
    readonly property int cardWidth: 264
    readonly property real scale: cardWidth / screenWidth
    readonly property int cardHeight: Math.round(screenHeight * scale)
    readonly property int activeWs: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int pad: Appearance.padding.large

    // Window yang sedang diseret dan posisi bayangannya
    property var dragged: null
    property point dragPos
    readonly property int dropWs: dragged ? wsAt(dragPos) : -1

    // Nomor workspace di titik p (koordinat root), -1 kalau di luar kartu
    function wsAt(p: point): int {
        const gx = p.x - grid.x;
        const gy = p.y - grid.y;
        const col = Math.floor(gx / (cardWidth + gap));
        const row = Math.floor(gy / (cardHeight + gap));
        if (gx < 0 || gy < 0 || col >= columns || gx - col * (cardWidth + gap) > cardWidth || gy - row * (cardHeight + gap) > cardHeight)
            return -1;
        const i = row * columns + col;
        return i < count ? i + 1 : -1;
    }

    implicitWidth: columns * cardWidth + (columns - 1) * gap + pad * 2
    implicitHeight: header.implicitHeight + Appearance.spacing.normal + rows * cardHeight + (rows - 1) * gap + pad * 2

    onShownChanged: {
        if (shown) {
            Hyprland.refreshToplevels();
            grid.forceActiveFocus();
        }
    }

    Row {
        id: header

        x: root.pad
        y: root.pad
        spacing: Appearance.spacing.normal

        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: "Overview"
            color: Appearance.colors.text
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 4
            height: 4
            radius: 2
            color: Appearance.colors.primary
        }

        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: "Klik window untuk fokus, seret ke workspace lain"
            font.letterSpacing: 1
        }
    }

    Grid {
        id: grid

        x: root.pad
        y: header.y + header.implicitHeight + Appearance.spacing.normal
        columns: root.columns
        spacing: root.gap
        focus: true
        Keys.onEscapePressed: DrawerState.close()

        Repeater {
            model: root.count

            StyledClippingRect {
                id: card

                required property int index
                readonly property int ws: index + 1
                readonly property bool isActive: ws === root.activeWs
                readonly property bool isDrop: root.dropWs === ws

                width: root.cardWidth
                height: root.cardHeight
                radius: Appearance.radius.normal
                color: Appearance.colors.surfaceContainer

                Image {
                    anchors.fill: parent
                    source: Wallpaper.current ? `file://${Wallpaper.current}` : ""
                    sourceSize: Qt.size(root.cardWidth * 2, root.cardHeight * 2)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.45
                }

                DisplayText {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: Appearance.padding.small
                    text: card.ws
                    color: card.isActive ? Appearance.colors.primary : Appearance.colors.text
                    weight: 900
                    font.pixelSize: Appearance.font.size.extraLarge
                    opacity: 0.9
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch(`workspace ${card.ws}`);
                        DrawerState.close();
                    }
                }

                Repeater {
                    model: ScriptModel {
                        values: Hyprland.toplevels.values.filter(t => t.workspace?.id === card.ws && t.lastIpcObject?.at)
                    }

                    Item {
                        id: win

                        required property HyprlandToplevel modelData
                        readonly property var ipc: modelData.lastIpcObject
                        readonly property var mon: modelData.monitor
                        readonly property var entry: modelData.wayland?.appId ? DesktopEntries.heuristicLookup(modelData.wayland.appId) : null
                        readonly property bool isDragged: root.dragged === modelData

                        x: (ipc.at[0] - (mon?.x ?? 0)) * root.scale
                        y: (ipc.at[1] - (mon?.y ?? 0)) * root.scale
                        width: Math.max(8, ipc.size[0] * root.scale)
                        height: Math.max(8, ipc.size[1] * root.scale)
                        opacity: isDragged ? 0.35 : 1

                        StyledClippingRect {
                            anchors.fill: parent
                            radius: Appearance.radius.small
                            color: Appearance.colors.surfaceContainerHigh
                            border.width: win.modelData.activated ? 2 : 0
                            border.color: Appearance.colors.primary

                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: root.shown ? win.modelData.wayland : null
                                live: true
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: Math.min(32, Math.min(parent.width, parent.height) * 0.5)
                                source: Quickshell.iconPath(win.entry?.icon || "application-x-executable", "application-x-executable")
                                asynchronous: true
                            }
                        }

                        MouseArea {
                            property point start

                            anchors.fill: parent
                            cursorShape: root.dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            onPressed: mouse => start = Qt.point(mouse.x, mouse.y)
                            onPositionChanged: mouse => {
                                if (!pressed)
                                    return;
                                if (!root.dragged && Math.hypot(mouse.x - start.x, mouse.y - start.y) > 6)
                                    root.dragged = win.modelData;
                                if (root.dragged)
                                    root.dragPos = mapToItem(root, mouse.x, mouse.y);
                            }
                            onReleased: {
                                if (root.dragged) {
                                    const target = root.dropWs;
                                    if (target > 0 && target !== card.ws) {
                                        Hyprland.dispatch(`movetoworkspacesilent ${target},address:${win.ipc.address}`);
                                        refresh.restart();
                                    }
                                    root.dragged = null;
                                    return;
                                }
                                Hyprland.dispatch(`focuswindow address:${win.ipc.address}`);
                                DrawerState.close();
                            }
                        }
                    }
                }

                // Garis tepi: primer untuk workspace aktif, tebal saat jadi tujuan seret
                Rectangle {
                    anchors.fill: parent
                    radius: card.radius
                    color: card.isDrop ? Appearance.alpha(Appearance.colors.primary, 0.15) : "transparent"
                    border.width: card.isDrop ? 3 : card.isActive ? 2 : 0
                    border.color: Appearance.colors.primary

                    Behavior on border.width {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }
                }
            }
        }
    }

    // Bayangan window yang diseret: ikon app mengikuti kursor
    StyledRect {
        visible: root.dragged !== null
        x: root.dragPos.x - width / 2
        y: root.dragPos.y - height / 2
        implicitWidth: 56
        implicitHeight: 56
        radius: Appearance.radius.normal
        color: Appearance.colors.primaryContainer

        IconImage {
            anchors.centerIn: parent
            implicitSize: 32
            source: {
                if (!root.dragged)
                    return "";
                const id = root.dragged.wayland?.appId ?? "";
                return Quickshell.iconPath((id ? DesktopEntries.heuristicLookup(id)?.icon : "") || "application-x-executable", "application-x-executable");
            }
        }
    }

    // lastIpcObject baru berubah setelah refresh
    Timer {
        id: refresh

        interval: 200
        onTriggered: Hyprland.refreshToplevels()
    }
}
