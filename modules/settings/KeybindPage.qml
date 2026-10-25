import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Klik UBAH lalu tekan kombinasi baru. Selama merekam, keybind Hyprland lain dimatikan (submap).
ColumnLayout {
    id: root

    property int capturing: -1

    function startCapture(i: int): void {
        capturing = i;
        Keybinds.startCapture();
        catcher.forceActiveFocus();
    }

    function stopCapture(): void {
        if (capturing < 0)
            return;
        capturing = -1;
        Keybinds.endCapture();
    }

    spacing: 2

    Component.onDestruction: stopCapture()

    // Penangkap tombol selama merekam
    Item {
        id: catcher

        Keys.onPressed: event => {
            event.accepted = true;
            if (event.key === Qt.Key_Escape) {
                root.stopCapture();
                return;
            }
            const combo = Keybinds.comboOf(event);
            if (!combo)
                return;
            Keybinds.setBind(Keybinds.binds[root.capturing].id, combo.mods, combo.key);
            root.stopCapture();
        }
    }

    Repeater {
        model: Keybinds.binds

        SettingRow {
            id: row

            required property var modelData
            required property int index
            readonly property bool isCapturing: root.capturing === index

            label: modelData.label
            description: `$meshell ${modelData.cmd}`

            Row {
                spacing: Appearance.spacing.large

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: row.isCapturing ? ["Tekan tombol..."] : [...row.modelData.mods.split(" ").filter(m => m), row.modelData.key]

                        // Tutup tombol keyboard
                        StyledRect {
                            required property string modelData

                            implicitWidth: Math.max(implicitHeight, cap.implicitWidth + 14)
                            implicitHeight: 28
                            radius: Appearance.radius.small - 4
                            color: row.isCapturing ? Appearance.colors.primaryContainer : Appearance.colors.surfaceContainerHighest

                            StyledText {
                                id: cap

                                anchors.centerIn: parent
                                text: parent.modelData
                                color: row.isCapturing ? Appearance.colors.primaryContainerText : Appearance.colors.text
                                font.family: Appearance.font.family.mono
                                font.pixelSize: Appearance.font.size.smaller
                                font.bold: true
                            }

                            // Berdenyut halus selama menunggu tombol
                            SequentialAnimation on opacity {
                                running: row.isCapturing
                                loops: Animation.Infinite
                                onStopped: parent.opacity = 1

                                Anim {
                                    to: 0.45
                                    duration: Appearance.anim.durations.large
                                }
                                Anim {
                                    to: 1
                                    duration: Appearance.anim.durations.large
                                }
                            }
                        }
                    }
                }

                TextButton {
                    anchors.verticalCenter: parent.verticalCenter
                    type: row.isCapturing ? "filled" : "tonal"
                    text: row.isCapturing ? "Batal" : "Ubah"
                    onClicked: {
                        if (row.isCapturing)
                            root.stopCapture();
                        else
                            root.startCapture(row.index);
                    }
                }
            }
        }
    }

    SettingSection {
        title: "File keybind (pola JaKooLit)"
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.normal
        implicitHeight: files.implicitHeight + Appearance.spacing.large * 2
        radius: Appearance.radius.small
        color: Appearance.colors.surfaceContainer

        StyledText {
            id: files

            anchors.fill: parent
            anchors.margins: Appearance.spacing.large
            textFormat: Text.PlainText
            color: Appearance.colors.textDim
            font.family: Appearance.font.family.mono
            font.pixelSize: Appearance.font.size.small
            text: `${Keybinds.dir}/
  me-shell.conf    di-source dari hyprland.conf
  keybinds.conf    dibuat dari halaman ini
  user.conf        punyamu sendiri, tidak pernah ditimpa

# di hyprland.conf cukup satu baris:
source = ${Keybinds.dir}/me-shell.conf`
        }
    }

    RowLayout {
        Layout.topMargin: Appearance.spacing.large

        TextButton {
            icon: "restart_alt"
            text: "Reset ke default"
            onClicked: Keybinds.resetAll()
        }
    }
}
