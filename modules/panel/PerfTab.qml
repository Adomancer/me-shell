import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Tab Performa: cincin CPU/RAM/Disk di atas, grafik riwayat dan jaringan di bawah.
ColumnLayout {
    id: root

    // Baris detail "label .... nilai"
    component Detail: RowLayout {
        property string label
        property string value

        Layout.fillWidth: true

        StyledText {
            text: parent.label
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.small
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: parent.value
            font.family: Appearance.font.family.mono
            font.pixelSize: Appearance.font.size.small
        }
    }

    component RingCard: Card {
        id: ring

        property real value
        property string label
        property color tint: Appearance.colors.primary
        default property alias details: info.data

        Layout.fillWidth: true
        Layout.fillHeight: true

        RowLayout {
            spacing: Appearance.spacing.large

            CircularProgress {
                value: ring.value
                label: ring.label
                size: 104
                thickness: 10
                color: ring.tint
            }

            ColumnLayout {
                id: info

                Layout.fillWidth: true
                spacing: 4
            }
        }
    }

    spacing: Appearance.spacing.normal

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        RingCard {
            title: "Prosesor"
            icon: "memory"
            value: SystemStats.cpu
            label: "CPU"

            StyledText {
                Layout.fillWidth: true
                text: SystemStats.cpuName
                font.pixelSize: Appearance.font.size.small
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Detail {
                visible: SystemStats.temp > 0
                label: "Suhu"
                value: `${Math.round(SystemStats.temp)}°C`
            }
        }

        RingCard {
            title: "Memori"
            icon: "memory_alt"
            value: SystemStats.memory
            label: "RAM"
            tint: Appearance.colors.secondary

            Detail {
                label: "Terpakai"
                value: `${SystemStats.memUsedGiB.toFixed(1)} GiB`
            }

            Detail {
                label: "Total"
                value: `${Math.round(SystemStats.memTotalGiB)} GiB`
            }

            Detail {
                label: "Swap"
                value: `${Math.round(SystemStats.swap * 100)}%`
            }
        }

        RingCard {
            title: "Penyimpanan"
            icon: "hard_drive"
            value: SystemStats.disk
            label: "DISK"
            tint: Appearance.colors.tertiary

            Detail {
                label: "Root"
                value: `${Math.round(SystemStats.diskUsedGiB)} / ${Math.round(SystemStats.diskTotalGiB)} GiB`
            }

            Detail {
                label: "Home"
                value: `${Math.round(SystemStats.home * 100)}%`
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.normal

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Riwayat"
            icon: "monitoring"
            note: "CPU · RAM"

            Item {
                Layout.fillWidth: true
                implicitHeight: 128

                Graph {
                    anchors.fill: parent
                    values: SystemStats.memHistory
                    color: Appearance.colors.secondary
                }

                Graph {
                    anchors.fill: parent
                    values: SystemStats.cpuHistory
                    grid: false
                }
            }
        }

        Card {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            title: "Jaringan"
            icon: "swap_vert"
            note: SystemStats.netIface

            RowLayout {
                spacing: Appearance.spacing.large

                Row {
                    spacing: 2

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "arrow_downward"
                        color: Appearance.colors.primary
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: SystemStats.formatSpeed(SystemStats.netRx)
                        font.family: Appearance.font.family.mono
                        font.pixelSize: Appearance.font.size.larger
                        font.bold: true
                    }
                }

                Row {
                    spacing: 2

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "arrow_upward"
                        color: Appearance.colors.tertiary
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: SystemStats.formatSpeed(SystemStats.netTx)
                        font.family: Appearance.font.family.mono
                        font.pixelSize: Appearance.font.size.larger
                        color: Appearance.colors.textDim
                    }
                }
            }

            Graph {
                Layout.fillWidth: true
                implicitHeight: 92
                values: SystemStats.netHistory
                // Skala ikut puncak terakhir, minimal 64 KB/s supaya diam tidak terlihat penuh
                maxValue: Math.max(65536, ...SystemStats.netHistory)
            }
        }
    }
}
