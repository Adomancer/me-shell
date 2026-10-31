import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    property string period: "today"
    readonly property var report: {
        Usage.revision;
        Usage.today;
        return Usage.summary(period);
    }
    readonly property var days: Usage.ready ? (report.days || []) : []
    readonly property var apps: Usage.ready ? (report.apps || []).slice().sort((a, b) => b.seconds - a.seconds) : []
    readonly property real total: Usage.ready ? report.total : 0
    readonly property real peak: Math.max(1, ...days.map(day => day.seconds))
    readonly property string periodLabel: period === "today" ? "Hari ini" : period === "week" ? "Minggu ini" : "Minggu lalu"

    spacing: Appearance.spacing.normal
    onPeriodChanged: list.positionViewAtBeginning()

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        Caption {
            Layout.fillWidth: true
            text: "Waktu penggunaan"
        }

        Row {
            spacing: Appearance.spacing.small

            Repeater {
                model: [
                    { key: "today", label: "Hari ini" },
                    { key: "week", label: "Minggu ini" },
                    { key: "lastWeek", label: "Minggu lalu" }
                ]

                TextButton {
                    required property var modelData

                    text: modelData.label
                    type: root.period === modelData.key ? "filled" : "text"
                    onClicked: root.period = modelData.key
                }
            }
        }

        TextButton {
            text: Usage.paused ? "Lanjutkan" : "Jeda"
            icon: Usage.paused ? "play_arrow" : "pause"
            disabled: !Config.usageEnabled || !Usage.ready
            onClicked: Usage.paused = !Usage.paused
        }
    }

    Divider {}

    RowLayout {
        Layout.fillWidth: true
        visible: Usage.storageError !== ""
        spacing: Appearance.spacing.small

        MaterialIcon {
            text: "error_outline"
            color: Appearance.colors.error
        }

        StyledText {
            Layout.fillWidth: true
            text: `Penyimpanan bermasalah: ${Usage.storageError}`
            color: Appearance.colors.error
            font.pixelSize: Appearance.font.size.small
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.huge

        ColumnLayout {
            Layout.preferredWidth: 360
            Layout.minimumWidth: 360
            Layout.maximumWidth: 360
            Layout.fillHeight: true
            spacing: Appearance.spacing.small

            Caption {
                text: `Total · ${root.periodLabel}`
                color: Appearance.colors.primary
            }

            DisplayText {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Usage.ready ? Usage.formatDuration(root.total) : "—"
                weight: 800
                font.pixelSize: 56
                minimumPixelSize: 28
                fontSizeMode: Text.Fit
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: Usage.ready ? `Periode sebelumnya · ${Usage.formatDuration(root.report.previousTotal)}` : "Memuat riwayat penggunaan…"
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                elide: Text.ElideRight
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: Appearance.spacing.small
            }

            Caption {
                text: "Aktivitas tujuh hari"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 150
                Layout.minimumHeight: 110
                spacing: Appearance.spacing.small

                Repeater {
                    model: 7

                    ColumnLayout {
                        id: day

                        required property int index
                        readonly property var entry: root.days[index]
                        readonly property real seconds: entry ? entry.seconds : 0
                        readonly property bool today: entry ? entry.today : false

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            text: Usage.ready && day.entry ? Usage.formatDuration(day.seconds) : "—"
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Appearance.font.family.mono
                            font.pixelSize: Appearance.font.size.small
                            color: day.today ? Appearance.colors.primary : Appearance.colors.textDim
                            elide: Text.ElideRight
                        }

                        SegmentBar {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            implicitWidth: 22
                            vertical: true
                            segments: 16
                            value: day.seconds / root.peak
                            onColor: day.today ? Appearance.colors.primary : Appearance.colors.textDim
                        }

                        Caption {
                            Layout.fillWidth: true
                            text: day.entry ? day.entry.label : "—"
                            horizontalAlignment: Text.AlignHCenter
                            font.letterSpacing: 0
                            color: day.today ? Appearance.colors.primary : Appearance.colors.textDim
                        }
                    }
                }
            }
        }

        Divider {
            vertical: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.fillWidth: true

                Caption {
                    Layout.fillWidth: true
                    text: "Aplikasi teratas"
                }

                StyledText {
                    text: String(root.apps.length).padStart(2, "0")
                    color: Appearance.colors.outline
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
                }
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Appearance.spacing.small
                boundsBehavior: Flickable.StopAtBounds
                model: root.apps

                delegate: Item {
                    id: app

                    required property var modelData
                    required property int index

                    width: ListView.view.width - Appearance.spacing.normal
                    implicitHeight: 58

                    RowLayout {
                        anchors.fill: parent
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.preferredWidth: 22
                            text: String(app.index + 1).padStart(2, "0")
                            color: Appearance.colors.outline
                            font.family: Appearance.font.family.mono
                            font.pixelSize: Appearance.font.size.small
                        }

                        AppIcon {
                            size: 26
                            icon: app.modelData.icon || "application-x-executable"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small

                                StyledText {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: app.modelData.name || app.modelData.id
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    text: Usage.formatDuration(app.modelData.seconds)
                                    color: Appearance.colors.textDim
                                    font.family: Appearance.font.family.mono
                                    font.pixelSize: Appearance.font.size.small
                                }
                            }

                            SegmentBar {
                                Layout.fillWidth: true
                                implicitHeight: 8
                                segments: 36
                                value: root.total > 0 ? app.modelData.seconds / root.total : 0
                                onColor: app.index === 0 ? Appearance.colors.primary : Appearance.colors.textDim
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - Appearance.padding.large * 2
                    visible: root.apps.length === 0
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: !Usage.ready ? "hourglass_empty" : Usage.storageError !== "" ? "error_outline" : "monitoring"
                        font.pixelSize: Appearance.font.size.extraLarge
                        color: Appearance.colors.outline
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: !Usage.ready ? "Memuat riwayat…" : Usage.storageError !== "" ? "Riwayat belum tersedia" : "Belum ada penggunaan"
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: !Usage.ready ? "Menyiapkan data penggunaan aplikasi." : !Config.usageEnabled ? "Pelacakan dinonaktifkan di pengaturan." : Usage.paused ? "Lanjutkan pelacakan untuk mencatat aktivitas." : "Tidak ada aktivitas tercatat pada periode ini."
                        horizontalAlignment: Text.AlignHCenter
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                        wrapMode: Text.Wrap
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    y: list.visibleArea.yPosition * list.height
                    width: 3
                    height: Math.min(list.height, list.visibleArea.heightRatio * list.height)
                    radius: width / 2
                    color: Appearance.colors.outline
                    visible: list.contentHeight > list.height
                }
            }
        }
    }

    Divider {}

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        Rectangle {
            implicitWidth: 6
            implicitHeight: 6
            radius: 3
            color: Usage.tracking && Config.usageEnabled && !Usage.paused ? Appearance.colors.primary : Appearance.colors.outline
        }

        StyledText {
            Layout.preferredWidth: 260
            Layout.maximumWidth: 260
            text: !Config.usageEnabled ? "Pelacakan dinonaktifkan" : Usage.paused ? "Pelacakan dijeda" : Usage.status
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.small
            elide: Text.ElideRight
        }

        MaterialIcon {
            text: "privacy_tip"
            color: Appearance.colors.outline
            font.pixelSize: Appearance.font.size.larger
        }

        StyledText {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.Wrap
            text: "Hanya aplikasi & durasi, tanpa judul jendela atau URL."
            color: Appearance.colors.outline
            font.pixelSize: Appearance.font.size.small
        }
    }
}
