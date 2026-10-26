import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components
import qs.services
import qs.utils
import qs.modules.bar
import qs.modules.bar.popouts
import qs.modules.panel
import qs.modules.launcher
import qs.modules.session
import qs.modules.notifs
import qs.modules.osd
import qs.modules.overview
import qs.modules.settings
import qs.modules.utilities

// Satu window transparan per monitor. Bar, bingkai layar, dan semua drawer digambar sebagai satu
// bentuk menyatu; drawer tumbuh dari tepi bingkai. Input hanya ditangkap di area yang terlihat (mask).
Scope {
    id: root

    required property ShellScreen modelData

    readonly property bool here: DrawerState.screen === "" || DrawerState.screen === modelData.name
    readonly property string active: here ? DrawerState.active : ""
    // Drawer yang terbuka karena hover tidak mengambil fokus keyboard (kursor yang lewat
    // tidak boleh memotong ketikan); setelah diklik (disematkan) baru mengambil fokus
    readonly property bool grabbing: active !== "" && !DrawerState.hoverOpened
    readonly property bool focused: (Hyprland.focusedMonitor?.name ?? modelData.name) === modelData.name
    readonly property int frame: Appearance.frame.thickness
    // Kursor masih di pemicu atau di drawer yang dibuka dengan hover. Satu nilai gabungan supaya
    // pindah dari pemicu ke drawer tidak sempat dianggap "keluar".
    readonly property bool hoverInside: bar.clockHovered || cornerZone.containsMouse || dash.hovered || utilities.hovered

    onHoverInsideChanged: {
        if (DrawerState.hoverOpened && root.here)
            hoverInside ? DrawerState.hoverHold() : DrawerState.hoverLeave();
    }

    // Zona hover di bingkai (ikut mask input). Nonaktif kalau hoverOpen dimatikan.
    component HotZone: MouseArea {
        enabled: Config.hoverOpen
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // Window kosong yang hanya memesan ruang (exclusive zone) untuk bar dan bingkai
    component Exclusion: PanelWindow {
        screen: root.modelData
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "me-shell-exclusion"
        implicitWidth: 1
        implicitHeight: 1
    }

    Exclusion {
        exclusiveZone: Config.barHeight
        anchors.top: true
        anchors.left: true
        anchors.right: true
    }
    Exclusion {
        exclusiveZone: root.frame
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
    }
    Exclusion {
        exclusiveZone: root.frame
        anchors.left: true
        anchors.top: true
        anchors.bottom: true
    }
    Exclusion {
        exclusiveZone: root.frame
        anchors.right: true
        anchors.top: true
        anchors.bottom: true
    }

    PanelWindow {
        id: win

        screen: root.modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "me-shell"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.grabbing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            regions: [
                Region {
                    item: bar
                },
                Region {
                    item: dash
                },
                Region {
                    item: launcher
                },
                Region {
                    item: session
                },
                Region {
                    item: osd
                },
                Region {
                    item: popups
                },
                Region {
                    item: settings
                },
                Region {
                    item: popout
                },
                Region {
                    item: utilities
                },
                Region {
                    item: overview
                },
                Region {
                    item: cornerZone
                },
                Region {
                    item: edgeZone
                }
            ]
        }

        // Hover jam sebentar = dashboard; pojok kanan bawah = utilitas; tepi kanan = slider OSD
        Timer {
            id: dashHover

            interval: 250
            onTriggered: DrawerState.hoverOpen("panel", root.modelData.name)
        }

        Timer {
            id: cornerHover

            interval: 150
            onTriggered: DrawerState.hoverOpen("utilities", root.modelData.name)
        }

        Connections {
            target: bar

            function onClockHoveredChanged(): void {
                if (bar.clockHovered && Config.hoverOpen && DrawerState.active === "")
                    dashHover.restart();
                else
                    dashHover.stop();
            }
        }

        HotZone {
            id: cornerZone

            x: win.width - width
            y: win.height - height
            width: 160
            height: Math.max(root.frame, 2)
            onContainsMouseChanged: containsMouse && DrawerState.active === "" ? cornerHover.restart() : cornerHover.stop()
        }

        HotZone {
            id: edgeZone

            x: win.width - width
            y: Math.round(win.height / 3)
            width: Math.max(root.frame, 2)
            height: Math.round(win.height / 3)
            onContainsMouseChanged: containsMouse ? OsdState.peek() : OsdState.release()
        }

        // Kafein: tahan idle (juga untuk hypridle kalau dipakai)
        IdleInhibitor {
            window: win
            enabled: Idle.inhibited
        }

        // Klik di luar drawer = tutup
        HyprlandFocusGrab {
            windows: [win]
            active: root.grabbing
            onCleared: DrawerState.close()
        }

        // Semua latar dalam satu Shape, dengan bayangan keras di sekelilingnya
        Item {
            anchors.fill: parent
            layer.enabled: true
            // Bayangan keras tanpa blur, bergeser ke kanan bawah (aksen retro)
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 0
                shadowBlur: 0
                shadowHorizontalOffset: 3
                shadowVerticalOffset: 3
                shadowColor: Appearance.alpha(Appearance.colors.shadow, 0.6)
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                Frame {
                    screenWidth: win.width
                    screenHeight: win.height
                    barHeight: Config.barHeight
                }
                PanelShape {
                    wrapper: dash
                    edge: "top"
                }
                PanelShape {
                    wrapper: launcher
                    edge: "bottom"
                }
                PanelShape {
                    wrapper: overview
                    edge: "top"
                }
                PanelShape {
                    wrapper: session
                    edge: "right"
                }
                PanelShape {
                    wrapper: osd
                    edge: "right"
                }
                CornerShape {
                    wrapper: popups
                }
                PanelShape {
                    wrapper: popout
                    edge: "top"
                }
                CornerShape {
                    wrapper: utilities
                    edge: "bottom"
                }
            }
        }

        Bar {
            id: bar

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            window: win
        }

        Wrapper {
            id: dash

            edge: "top"
            shown: root.active === "panel"
            x: Math.round((parent.width - width) / 2)
            y: Config.barHeight

            ControlPanel {
                shown: dash.shown
            }
        }

        Wrapper {
            id: overview

            edge: "top"
            shown: root.active === "overview"
            x: Math.round((parent.width - width) / 2)
            y: Config.barHeight

            Overview {
                shown: overview.shown
                screenWidth: win.width
                screenHeight: win.height
            }
        }

        Wrapper {
            id: launcher

            edge: "bottom"
            shown: root.active === "launcher"
            x: Math.round((parent.width - width) / 2)
            y: parent.height - root.frame - height

            Launcher {
                shown: launcher.shown
            }
        }

        Wrapper {
            id: session

            edge: "right"
            shown: root.active === "session"
            x: parent.width - root.frame - width
            y: Math.round((parent.height - height) / 2)

            SessionMenu {
                shown: session.shown
            }
        }

        Wrapper {
            id: osd

            edge: "right"
            shown: OsdState.shown && root.focused && root.active !== "session"
            x: parent.width - root.frame - width
            y: Math.round((parent.height - height) / 2)

            Osd {}
        }

        Wrapper {
            id: popups

            edge: "top"
            shown: list.count > 0
            x: parent.width - root.frame - width
            y: Config.barHeight

            Popups {
                id: list

                active: root.focused
            }
        }

        // Popout bar: turun dari bar di bawah ikon yang di-hover. Titik tengahnya meluncur dengan pegas
        // saat kursor pindah ikon, ukurannya ikut halaman yang tampil.
        Wrapper {
            id: popout

            property real cx: DrawerState.popoutX

            edge: "top"
            shown: Config.barPopouts && DrawerState.popout !== "" && DrawerState.popoutScreen === root.modelData.name
            x: Math.round(Math.max(root.frame + Appearance.frame.rounding, Math.min(win.width - root.frame - Appearance.frame.rounding - width, cx - width / 2)))
            y: Config.barHeight

            Behavior on cx {
                enabled: popout.visible

                Anim {
                    duration: Appearance.anim.durations.expressiveDefault
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
            }

            Popouts {}
        }

        // Pojok kanan bawah: toast dari shell, plus panel utilitas saat dibuka
        Wrapper {
            id: utilities

            edge: "bottom"
            shown: root.active === "utilities" || (Toaster.toasts.length > 0 && root.focused)
            x: parent.width - root.frame - width
            y: parent.height - root.frame - height

            UtilitiesDrawer {
                open: root.active === "utilities"
            }
        }

        SettingsWindow {
            id: settings

            anchors.centerIn: parent
            shown: root.active === "settings"
        }
    }
}
