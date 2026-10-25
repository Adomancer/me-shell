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
import qs.modules.panel
import qs.modules.launcher
import qs.modules.session
import qs.modules.notifs
import qs.modules.osd
import qs.modules.settings

// Satu window transparan per monitor. Bar, bingkai layar, dan semua drawer digambar sebagai satu
// bentuk menyatu; drawer tumbuh dari tepi bingkai. Input hanya ditangkap di area yang terlihat (mask).
Scope {
    id: root

    required property ShellScreen modelData

    readonly property bool here: DrawerState.screen === "" || DrawerState.screen === modelData.name
    readonly property string active: here ? DrawerState.active : ""
    readonly property bool focused: (Hyprland.focusedMonitor?.name ?? modelData.name) === modelData.name
    readonly property int frame: Appearance.frame.thickness

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
        WlrLayershell.keyboardFocus: root.active !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
                }
            ]
        }

        // Klik di luar drawer = tutup
        HyprlandFocusGrab {
            windows: [win]
            active: root.active !== ""
            onCleared: DrawerState.close()
        }

        // Semua latar dalam satu Shape, dengan bayangan lembut di sekelilingnya
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 18
                shadowBlur: 1
                shadowColor: Appearance.alpha(Appearance.colors.shadow, 0.55)
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

        SettingsWindow {
            id: settings

            anchors.centerIn: parent
            shown: root.active === "settings"
        }
    }
}
