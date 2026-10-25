import QtQuick
import qs.components
import qs.services
import qs.utils

// Control panel bertab ala dashboard Caelestia, turun dari jam di bar.
// Pindah tab: noise ala ganti channel TV, lalu halaman masuk patah-patah.
Reveal {
    id: root

    component Page: Item {
        id: page

        property string name
        property real progress: 1
        readonly property real stepped: Math.round(progress * 5) / 5

        anchors.fill: parent
        visible: root.tab === name
        opacity: stepped
        onVisibleChanged: {
            if (visible)
                enter.restart();
        }

        transform: Translate {
            x: (1 - page.stepped) * -24
        }

        SequentialAnimation {
            id: enter

            PropertyAction {
                target: page
                property: "progress"
                value: 0
            }
            NumberAnimation {
                target: page
                property: "progress"
                to: 1
                duration: 260
            }
        }
    }

    // Disimpan di DrawerState supaya IPC `drawers panel <tab>` bisa memilih tab
    readonly property string tab: DrawerState.panelTab
    readonly property var tabs: ["dash", "media", "perf", "weather", "notif"]
    readonly property int contentWidth: 856
    readonly property bool usingCava: shown && tab === "media"
    property real noise: 0

    function setTab(name: string): void {
        DrawerState.panelTab = name;
    }

    function shiftTab(delta: int): void {
        setTab(tabs[(tabs.indexOf(tab) + delta + tabs.length) % tabs.length]);
    }

    edge: "top"
    onShownChanged: {
        if (shown)
            frame.forceActiveFocus();
    }
    onUsingCavaChanged: Cava.users += usingCava ? 1 : -1
    onTabChanged: noiseAnim.restart()

    NumberAnimation {
        id: noiseAnim

        target: root
        property: "noise"
        from: 1
        to: 0
        duration: 220
    }

    RetroFrame {
        id: frame

        title: "control"
        focus: true
        Keys.onEscapePressed: DrawerState.close()
        Keys.onLeftPressed: root.shiftTab(-1)
        Keys.onRightPressed: root.shiftTab(1)

        Column {
            width: root.contentWidth
            spacing: Appearance.spacing.large

            TabBar {
                width: parent.width
                current: root.tab
                onSelected: name => root.setTab(name)
            }

            Item {
                width: parent.width
                height: 420

                Page {
                    name: "dash"

                    DashTab {
                        anchors.fill: parent
                    }
                }

                Page {
                    name: "media"

                    MediaTab {
                        anchors.fill: parent
                    }
                }

                Page {
                    name: "perf"

                    PerfTab {
                        anchors.fill: parent
                    }
                }

                Page {
                    name: "weather"

                    WeatherTab {
                        anchors.fill: parent
                    }
                }

                Page {
                    name: "notif"

                    NotifTab {
                        anchors.fill: parent
                    }
                }

                // Noise statis saat pindah tab, dibulatkan ke 4 langkah
                Image {
                    readonly property real level: Math.round(root.noise * 4) / 4

                    anchors.fill: parent
                    anchors.topMargin: level * 6
                    visible: level > 0
                    opacity: level * 0.9
                    source: Qt.resolvedUrl("../../assets/scanlines.svg")
                    fillMode: Image.Tile
                    sourceSize: Qt.size(4, 4)
                    smooth: false

                    Rectangle {
                        anchors.fill: parent
                        color: Appearance.colors.text
                        opacity: 0.08
                    }
                }
            }
        }
    }
}
