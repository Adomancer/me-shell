import QtQuick
import qs.components
import qs.services
import qs.utils

// CPU/RAM/disk/suhu sebagai bar bersegmen.
Tile {
    id: root

    readonly property var stats: [
        {
            label: "CPU",
            value: SystemStats.cpu
        },
        {
            label: "RAM",
            value: SystemStats.memory
        },
        {
            label: "Disk",
            value: SystemStats.disk
        },
        {
            label: "Suhu",
            // Skala 0-100°C
            value: SystemStats.temp / 100,
            text: `${Math.round(SystemStats.temp)}°`,
            hot: SystemStats.temp >= 80
        }
    ].filter(s => s.label !== "Suhu" || SystemStats.temp > 0)

    Caption {
        id: title

        anchors.left: parent.left
        anchors.top: parent.top
        text: "Resource"
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.topMargin: Appearance.spacing.normal
        anchors.bottom: parent.bottom

        Repeater {
            model: root.stats

            Item {
                required property var modelData

                width: parent.width
                height: parent.height / root.stats.length

                Caption {
                    id: label

                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: parent.modelData.label
                }

                StyledText {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: parent.modelData.text ?? `${Math.round(parent.modelData.value * 100)}%`
                    color: parent.modelData.hot ? Appearance.colors.error : Appearance.colors.text
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
                }

                SegmentBar {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: label.bottom
                    anchors.topMargin: Appearance.spacing.small
                    height: 10
                    segments: 28
                    value: parent.modelData.value
                    onColor: parent.modelData.hot ? Appearance.colors.error : Appearance.colors.primary
                }
            }
        }
    }
}
