import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

GridLayout {
    id: root

    component Big: StyledText {
        font.pixelSize: 26
        font.bold: true
    }

    component Label: StyledText {
        Layout.preferredWidth: 44
        color: Appearance.colors.textDim
        font.pixelSize: Appearance.font.size.small
        font.bold: true
    }

    component Pct: StyledText {
        Layout.preferredWidth: 44
        horizontalAlignment: Text.AlignRight
        font.pixelSize: Appearance.font.size.small
    }

    columns: 2
    columnSpacing: Appearance.spacing.normal
    rowSpacing: Appearance.spacing.normal

    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "cpu"
        note: SystemStats.temp > 0 ? `${SystemStats.cpuName} · ${Math.round(SystemStats.temp)}°C` : SystemStats.cpuName

        Big {
            text: `${Math.round(SystemStats.cpu * 100)}%`
        }

        Graph {
            Layout.fillWidth: true
            values: SystemStats.cpuHistory
        }
    }

    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "ram"
        note: `${SystemStats.memUsedGiB.toFixed(1)} / ${Math.round(SystemStats.memTotalGiB)} GiB`

        Big {
            text: `${Math.round(SystemStats.memory * 100)}%`
        }

        Graph {
            Layout.fillWidth: true
            values: SystemStats.memHistory
        }
    }

    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "net"
        note: SystemStats.netIface

        Big {
            text: `↓ ${SystemStats.formatSpeed(SystemStats.netRx)}`
        }

        StyledText {
            text: `↑ ${SystemStats.formatSpeed(SystemStats.netTx)}`
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.small
        }

        Graph {
            Layout.fillWidth: true
            implicitHeight: 72
            values: SystemStats.netHistory
            // Skala ikut puncak terakhir, minimal 64 KB/s supaya diam tidak terlihat penuh
            maxValue: Math.max(65536, ...SystemStats.netHistory)
        }
    }

    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "disk"
        note: `/ · ${Math.round(SystemStats.diskUsedGiB)} / ${Math.round(SystemStats.diskTotalGiB)} GiB`

        Big {
            text: `${Math.round(SystemStats.disk * 100)}%`
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Appearance.spacing.normal
            rowSpacing: 4

            Label {
                text: "ROOT"
            }
            BlockBar {
                Layout.fillWidth: true
                value: SystemStats.disk
            }
            Pct {
                text: `${Math.round(SystemStats.disk * 100)}%`
            }

            Label {
                text: "HOME"
            }
            BlockBar {
                Layout.fillWidth: true
                value: SystemStats.home
            }
            Pct {
                text: `${Math.round(SystemStats.home * 100)}%`
            }

            Label {
                text: "SWAP"
            }
            BlockBar {
                Layout.fillWidth: true
                value: SystemStats.swap
            }
            Pct {
                text: `${Math.round(SystemStats.swap * 100)}%`
            }
        }
    }
}
