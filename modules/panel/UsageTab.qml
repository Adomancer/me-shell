import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules.settings
import qs.services
import qs.utils

ColumnLayout {
    id: root

    property string period: "today"
    property string mode: "apps"
    property int hoveredDay: -1
    readonly property bool monthly: period === "month" || period === "lastMonth"
    readonly property var periodLabels: ({
        today: "Hari ini",
        week: "Minggu ini",
        lastWeek: "Minggu lalu",
        month: "Bulan ini",
        lastMonth: "Bulan lalu"
    })
    readonly property var report: {
        Usage.revision;
        Usage.today;
        Config.usageAppCategories;
        return Usage.summary(period);
    }
    readonly property var days: Usage.ready ? (report.days || []) : []
    readonly property var apps: Usage.ready ? (report.apps || []).slice().sort((a, b) => b.seconds - a.seconds) : []
    readonly property var categories: Usage.ready ? (report.categories || []).filter(category => category.seconds > 0).sort((a, b) => b.seconds - a.seconds) : []
    readonly property var entries: mode === "categories" ? categories : apps
    readonly property var categoryOptions: ["", ...Usage.categories.map(category => category.id)]
    readonly property real total: Usage.ready ? report.total : 0
    readonly property real peak: Math.max(1, ...days.map(day => day.seconds))
    readonly property string periodLabel: monthly && Usage.ready ? report.monthLabel : periodLabels[period]
    readonly property int retentionDays: Math.max(21, Math.min(365, Config.usageRetentionDays))
    readonly property string retentionBoundary: {
        // Parse as a local calendar date, not an ISO timestamp (UTC).
        const parts = Usage.today.split("-").map(Number);
        const cutoff = new Date(parts[0], parts[1] - 1, parts[2]);
        cutoff.setDate(cutoff.getDate() + 1 - retentionDays);
        return `${cutoff.getFullYear()}-${String(cutoff.getMonth() + 1).padStart(2, "0")}-${String(cutoff.getDate()).padStart(2, "0")}`;
    }
    readonly property bool retentionLimited: monthly && Usage.ready
        && (report.start < retentionBoundary || report.comparisonStart < retentionBoundary)
    readonly property string monthlyComparison: {
        if (!monthly || !Usage.ready)
            return "Memuat riwayat penggunaan…";
        const change = report.change;
        const direction = change > 0 ? "Naik" : change < 0 ? "Turun" : "Tetap";
        const difference = change === 0 ? direction : `${direction} ${Usage.formatDuration(Math.abs(change))}`;
        const percent = report.changePercent === null ? "tanpa acuan persentase" : `${Math.abs(report.changePercent).toFixed(1).replace(".", ",")}%`;
        return `${report.comparisonDays} hari pertama di kedua bulan\n${Usage.formatDuration(report.comparisonTotal)} vs ${Usage.formatDuration(report.previousTotal)} · bulan sebelumnya\n${difference} · ${percent}`;
    }

    spacing: Appearance.spacing.normal
    onPeriodChanged: {
        hoveredDay = -1;
        list.positionViewAtBeginning();
    }
    onModeChanged: list.positionViewAtBeginning()

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        Caption {
            Layout.fillWidth: true
            text: "Waktu penggunaan"
        }

        SettingCycle {
            labelWidth: 120
            options: ["today", "week", "lastWeek", "month", "lastMonth"]
            value: root.period
            format: v => root.periodLabels[v]
            onPicked: v => root.period = v
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
                font.pixelSize: root.monthly ? 44 : 56
                minimumPixelSize: 28
                fontSizeMode: Text.Fit
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.monthly
                text: Usage.ready ? `Rata-rata harian · ${Usage.formatDuration(root.report.average)} · ${root.report.elapsedDays} hari` : "Rata-rata harian · —"
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.monthly ? root.monthlyComparison : Usage.ready ? `Periode sebelumnya · ${Usage.formatDuration(root.report.previousTotal)}` : "Memuat riwayat penggunaan…"
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                wrapMode: root.monthly ? Text.Wrap : Text.NoWrap
                elide: Text.ElideRight
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: Appearance.spacing.small
            }

            Caption {
                Layout.fillWidth: true
                text: root.monthly ? root.hoveredDay >= 0 && root.days[root.hoveredDay]
                    ? `${root.days[root.hoveredDay].date} · ${Usage.formatDuration(root.days[root.hoveredDay].future ? 0 : root.days[root.hoveredDay].seconds)}`
                    : "Aktivitas harian · arahkan penunjuk" : "Aktivitas tujuh hari"
                font.letterSpacing: root.monthly ? 0 : 1.5
                elide: Text.ElideRight
            }

            RowLayout {
                id: chart

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: root.monthly ? 100 : 150
                Layout.minimumHeight: root.monthly ? 50 : 110
                spacing: root.monthly ? 2 : Appearance.spacing.small

                Repeater {
                    model: root.monthly ? root.days.length : 7

                    ColumnLayout {
                        id: day

                        required property int index
                        readonly property var entry: root.days[index]
                        readonly property real seconds: entry && !entry.future ? entry.seconds : 0
                        readonly property bool today: entry ? entry.today : false
                        readonly property bool future: entry ? !!entry.future : false

                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            visible: !root.monthly
                            text: Usage.ready && day.entry ? Usage.formatDuration(day.seconds) : "—"
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Appearance.font.family.mono
                            font.pixelSize: Appearance.font.size.small
                            color: day.today ? Appearance.colors.primary : Appearance.colors.textDim
                            elide: Text.ElideRight
                        }

                        SegmentBar {
                            visible: !root.monthly
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            implicitWidth: 22
                            vertical: true
                            segments: 16
                            value: day.seconds / root.peak
                            onColor: day.today ? Appearance.colors.primary : Appearance.colors.textDim
                        }

                        Item {
                            visible: root.monthly
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            opacity: day.future ? 0.3 : 1

                            Rectangle {
                                anchors.fill: parent
                                color: Appearance.colors.surfaceContainerHighest
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: day.seconds > 0 ? Math.max(2, parent.height * day.seconds / root.peak) : 0
                                color: day.today || root.hoveredDay === day.index ? Appearance.colors.primary : Appearance.colors.textDim
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                onEntered: root.hoveredDay = day.index
                                onExited: {
                                    if (root.hoveredDay === day.index)
                                        root.hoveredDay = -1;
                                }
                            }
                        }

                        Caption {
                            Layout.fillWidth: true
                            visible: !root.monthly
                            text: day.entry ? day.entry.label : "—"
                            horizontalAlignment: Text.AlignHCenter
                            font.letterSpacing: 0
                            color: day.today ? Appearance.colors.primary : Appearance.colors.textDim
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: Appearance.font.size.small + 2
                visible: root.monthly

                Repeater {
                    model: root.monthly ? root.days : []

                    StyledText {
                        required property var modelData
                        required property int index
                        readonly property real cellWidth: (chart.width - chart.spacing * (root.days.length - 1)) / Math.max(1, root.days.length)

                        width: 20
                        x: Math.max(0, Math.min(parent.width - width, index * (cellWidth + chart.spacing) + cellWidth / 2 - width / 2))
                        text: modelData.label
                        visible: index === 0 || ((index + 1) <= 25 && (index + 1) % 5 === 0) || index === root.days.length - 1
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.size.small
                        color: modelData.today ? Appearance.colors.primary : Appearance.colors.textDim
                        opacity: modelData.future ? 0.3 : 1
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

                Row {
                    spacing: Appearance.spacing.small

                    TextButton {
                        text: "Aplikasi"
                        type: root.mode === "apps" ? "filled" : "text"
                        onClicked: root.mode = "apps"
                    }

                    TextButton {
                        text: "Kategori"
                        type: root.mode === "categories" ? "filled" : "text"
                        onClicked: root.mode = "categories"
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: String(root.entries.length).padStart(2, "0")
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
                model: root.entries

                delegate: Item {
                    id: app

                    required property var modelData
                    required property int index
                    readonly property bool isCategory: root.mode === "categories"
                    readonly property var desktopEntry: {
                        DesktopEntries.applications.values;
                        return !isCategory ? DesktopEntries.heuristicLookup(modelData.id) : null;
                    }
                    readonly property string displayName: desktopEntry?.name || modelData.name || modelData.id || "?"
                    readonly property string appIconName: desktopEntry?.icon || modelData.icon || "application-x-executable"
                    // Jangan tampilkan ikon generik/mosaik jika identitas ikon aplikasi belum tersedia.
                    readonly property string appIconSource: !isCategory && (desktopEntry?.icon || modelData.icon) ? Quickshell.iconPath(appIconName, true) : ""

                    width: ListView.view.width - Appearance.spacing.normal
                    implicitHeight: isCategory ? 58 : 72

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

                        Item {
                            visible: !app.isCategory
                            implicitWidth: 26
                            implicitHeight: 26

                            AppIcon {
                                anchors.fill: parent
                                visible: app.appIconSource !== ""
                                size: 26
                                icon: app.appIconName
                                source: app.appIconSource
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: app.appIconSource === ""
                                radius: width / 2
                                color: Appearance.colors.primaryContainer

                                StyledText {
                                    anchors.centerIn: parent
                                    text: (Array.from(app.displayName.trim())[0] || "?").toUpperCase()
                                    color: Appearance.colors.primary
                                    font.family: Appearance.font.family.mono
                                    font.pixelSize: Appearance.font.size.larger
                                }
                            }
                        }

                        MaterialIcon {
                            visible: app.isCategory
                            text: app.modelData.icon || "category"
                            font.pixelSize: 26
                            color: Appearance.colors.primary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small

                                StyledText {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: app.isCategory ? app.modelData.label : app.displayName
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    text: Usage.formatDuration(app.modelData.seconds)
                                    color: Appearance.colors.textDim
                                    font.family: Appearance.font.family.mono
                                    font.pixelSize: Appearance.font.size.small
                                }
                            }

                            SettingCycle {
                                visible: !app.isCategory
                                labelWidth: Math.max(0, Math.min(160, app.width - 150))
                                options: root.categoryOptions
                                value: {
                                    Config.usageAppCategories;
                                    return app.isCategory ? "" : Usage.categoryOverride(app.modelData.id);
                                }
                                format: v => app.isCategory ? "" : v === "" ? `Otomatis · ${Usage.categoryLabel(app.modelData.category)}` : Usage.categoryLabel(v)
                                onPicked: v => Usage.setCategory(app.modelData.id, v)
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
                    visible: root.entries.length === 0
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

    StyledText {
        Layout.fillWidth: true
        visible: root.monthly
        text: "Hanya riwayat tersimpan; hari kosong mungkin belum tercatat."
            + (root.retentionLimited ? `\nRetensi ${root.retentionDays} hari membatasi total dan perbandingan.` : "")
        color: root.retentionLimited ? Appearance.colors.error : Appearance.colors.textDim
        font.pixelSize: Appearance.font.size.small
        wrapMode: Text.Wrap
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
