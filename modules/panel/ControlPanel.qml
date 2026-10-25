import QtQuick
import qs.components
import qs.services
import qs.utils

// Dashboard bertab yang turun dari bar. Halaman disusun mendatar dan bergeser halus saat pindah tab.
Item {
    id: root

    property bool shown: false

    // Disimpan di DrawerState supaya IPC `drawers panel <tab>` bisa memilih tab
    readonly property string tab: DrawerState.panelTab
    readonly property var tabs: ["dash", "media", "perf", "weather", "notif"]
    readonly property int index: Math.max(0, tabs.indexOf(tab))
    readonly property int pageWidth: 856
    readonly property int pageHeight: 420
    readonly property bool usingCava: shown && tab === "media"

    function setTab(name: string): void {
        DrawerState.panelTab = name;
    }

    function shiftTab(delta: int): void {
        setTab(tabs[(index + delta + tabs.length) % tabs.length]);
    }

    implicitWidth: pageWidth + Appearance.padding.large * 2
    implicitHeight: col.implicitHeight + Appearance.padding.large * 2

    onShownChanged: {
        if (shown)
            col.forceActiveFocus();
    }
    onUsingCavaChanged: Cava.users += usingCava ? 1 : -1

    Column {
        id: col

        x: Appearance.padding.large
        y: Appearance.padding.large
        width: root.pageWidth
        spacing: Appearance.spacing.large
        focus: true
        Keys.onEscapePressed: DrawerState.close()
        Keys.onLeftPressed: root.shiftTab(-1)
        Keys.onRightPressed: root.shiftTab(1)

        TabBar {
            width: parent.width
            current: root.tab
            onSelected: name => root.setTab(name)
        }

        Item {
            width: parent.width
            height: root.pageHeight
            clip: true

            Row {
                id: pages

                x: -root.index * root.pageWidth

                Behavior on x {
                    Anim {
                        duration: Appearance.anim.durations.large
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }

                DashTab {
                    width: root.pageWidth
                    height: root.pageHeight
                }
                MediaTab {
                    width: root.pageWidth
                    height: root.pageHeight
                }
                PerfTab {
                    width: root.pageWidth
                    height: root.pageHeight
                }
                WeatherTab {
                    width: root.pageWidth
                    height: root.pageHeight
                }
                NotifTab {
                    width: root.pageWidth
                    height: root.pageHeight
                }
            }
        }
    }
}
