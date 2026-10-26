import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Tab Fokus tanpa kotak: timer pomodoro/stopwatch sebagai cincin titik + angka dot-matrix di kiri, daftar
// tugas bernomor di kanan, dipisah garis tipis.
RowLayout {
    id: root

    spacing: Appearance.spacing.huge

    // Kiri: timer; layout default ikut melebar, jadi lebarnya dikunci
    ColumnLayout {
        Layout.fillWidth: false
        Layout.preferredWidth: 380
        Layout.fillHeight: true
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true

            Caption {
                Layout.fillWidth: true
                text: Focus.label
                color: Focus.running ? Appearance.colors.primary : Appearance.colors.textDim
            }

            Caption {
                text: `Sesi hari ini ${String(Focus.sessions).padStart(2, "0")}`
            }
        }

        DotRing {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.spacing.small
            size: 250
            dots: 60
            dotSize: 5
            value: Focus.progress
            onColor: Focus.mode === "break" ? Appearance.colors.text : Appearance.colors.primary

            DisplayText {
                anchors.centerIn: parent
                text: Focus.text
                weight: 800
                font.pixelSize: Focus.text.length > 5 ? 44 : 60
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // Kontrol: berhenti, putar/jeda (aksi utama), istirahat
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.normal

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                type: "tonal"
                icon: "stop"
                size: Appearance.font.size.extraLarge - 6
                padding: Appearance.padding.normal
                disabled: Focus.mode === "idle"
                onClicked: Focus.stop()
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                type: "filled"
                toggled: true
                icon: Focus.running ? "pause" : "play_arrow"
                size: 32
                padding: Appearance.padding.normal + 2
                onClicked: Focus.toggle()
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                type: "tonal"
                icon: "coffee"
                size: Appearance.font.size.extraLarge - 6
                padding: Appearance.padding.normal
                toggled: Focus.mode === "break"
                onClicked: Focus.startBreak()
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small

            TextButton {
                type: Focus.mode === "focus" ? "tonal" : "text"
                text: `Fokus ${Config.focusMinutes}`
                onClicked: Focus.startFocus()
            }

            TextButton {
                type: Focus.mode === "stopwatch" ? "tonal" : "text"
                text: "Stopwatch"
                onClicked: Focus.startStopwatch()
            }
        }
    }

    Divider {
        vertical: true
    }

    // Kanan: tugas
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            DisplayText {
                text: String(Todo.pending).padStart(2, "0")
                weight: 800
                color: Todo.pending > 0 ? Appearance.colors.primary : Appearance.colors.outline
                font.pixelSize: 34
            }

            Caption {
                Layout.fillWidth: true
                text: "Tugas"
            }

            TextButton {
                visible: Todo.items.length > Todo.pending
                type: "text"
                icon: "done_all"
                text: "Hapus selesai"
                onClicked: Todo.clearDone()
            }
        }

        // Kolom tambah tugas: garis bawah, Enter untuk simpan
        Item {
            Layout.fillWidth: true
            implicitHeight: 40

            MaterialIcon {
                id: addIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "add"
                color: Appearance.colors.primary
            }

            TextInput {
                id: input

                anchors.left: addIcon.right
                anchors.leftMargin: Appearance.spacing.normal
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Appearance.colors.text
                font.family: Appearance.font.family.sans
                font.pixelSize: Appearance.font.size.larger
                selectionColor: Appearance.colors.primary
                selectedTextColor: Appearance.colors.primaryText
                clip: true
                Keys.onReturnPressed: {
                    Todo.add(text);
                    text = "";
                }
                Keys.onEnterPressed: {
                    Todo.add(text);
                    text = "";
                }
                Keys.onEscapePressed: DrawerState.close()

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: "Tambah tugas, Enter untuk simpan"
                    color: Appearance.colors.outline
                    font: input.font
                }
            }

            Divider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: Todo.items

            delegate: Item {
                id: row

                required property var modelData
                required property int index

                width: ListView.view.width
                implicitHeight: 40

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacing.normal

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(row.index + 1).padStart(2, "0")
                        color: Appearance.colors.outline
                        font.family: Appearance.font.family.mono
                        font.pixelSize: Appearance.font.size.small
                    }

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.done ? "check_circle" : "radio_button_unchecked"
                        fill: row.modelData.done ? 1 : 0
                        color: row.modelData.done ? Appearance.colors.primary : Appearance.colors.textDim
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.width - 120
                        text: row.modelData.text
                        color: row.modelData.done ? Appearance.colors.outline : Appearance.colors.text
                        font.strikeout: row.modelData.done
                        elide: Text.ElideRight
                    }
                }

                StateLayer {
                    id: rowLayer

                    radius: Appearance.radius.small
                    onClicked: Todo.toggle(row.modelData.id)
                }

                // Hapus: muncul saat baris di-hover
                IconButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: rowLayer.containsMouse || closeHover.hovered
                    icon: "close"
                    onClicked: Todo.remove(row.modelData.id)

                    HoverHandler {
                        id: closeHover
                    }
                }
            }

            StyledText {
                parent: list
                anchors.centerIn: parent
                visible: Todo.items.length === 0
                text: "Belum ada tugas. Bisa juga lewat /todo di launcher"
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
            }
        }
    }
}
