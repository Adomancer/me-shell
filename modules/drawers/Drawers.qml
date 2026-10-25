import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.utils
import qs.modules.bar
import qs.modules.panel
import qs.modules.launcher
import qs.modules.session
import qs.modules.notifs
import qs.modules.osd
import qs.modules.settings

// Satu window transparan per monitor. Bar dan semua drawer hidup di permukaan yang sama,
// input hanya ditangkap di area yang terlihat (mask).
Scope {
    id: root

    required property ShellScreen modelData

    readonly property bool here: DrawerState.screen === "" || DrawerState.screen === modelData.name
    readonly property string active: here ? DrawerState.active : ""
    readonly property bool focused: (Hyprland.focusedMonitor?.name ?? modelData.name) === modelData.name

    // Window kosong yang hanya memesan ruang (exclusive zone) untuk bar
    PanelWindow {
        screen: root.modelData
        color: "transparent"
        implicitHeight: Config.barHeight
        exclusiveZone: Config.barHeight
        mask: Region {}
        WlrLayershell.namespace: "me-shell-exclusion"

        anchors {
            top: true
            left: true
            right: true
        }
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
                    item: panel
                },
                Region {
                    item: launcher
                },
                Region {
                    item: session.hitArea
                },
                Region {
                    item: settings
                },
                Region {
                    item: popups
                }
            ]
        }

        // Klik di luar drawer = tutup
        HyprlandFocusGrab {
            windows: [win]
            active: root.active !== ""
            onCleared: DrawerState.close()
        }

        Bar {
            id: bar

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            window: win
        }

        ControlPanel {
            id: panel

            anchors.top: bar.bottom
            anchors.topMargin: Appearance.spacing.normal
            anchors.horizontalCenter: parent.horizontalCenter
            shown: root.active === "panel"
        }

        Popups {
            id: popups

            anchors.top: bar.bottom
            anchors.right: parent.right
            anchors.margins: Appearance.spacing.large
            active: root.focused
        }

        Osd {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 80
            anchors.horizontalCenter: parent.horizontalCenter
            shown: OsdState.shown && root.focused
        }

        Launcher {
            id: launcher

            anchors.centerIn: parent
            shown: root.active === "launcher"
        }

        SettingsWindow {
            id: settings

            anchors.centerIn: parent
            shown: root.active === "settings"
        }

        SessionMenu {
            id: session

            anchors.fill: parent
            shown: root.active === "session"
        }
    }
}
