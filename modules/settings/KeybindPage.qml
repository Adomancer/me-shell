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

    spacing: 0

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
                        model: row.isCapturing ? ["TEKAN TOMBOL..."] : [...row.modelData.mods.split(" ").filter(m => m), row.modelData.key]

                        // Tombol keyboard: border bawah lebih tebal
                        Rectangle {
                            required property string modelData

                            implicitWidth: cap.implicitWidth + 12
                            implicitHeight: cap.implicitHeight + 6
                            radius: Appearance.radius.small
                            color: Appearance.colors.surfaceHigh
                            border.width: Appearance.border.thin
                            border.color: row.isCapturing ? Appearance.colors.primary : Appearance.colors.outline

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 3
                                color: parent.border.color
                            }

                            StyledText {
                                id: cap

                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -1
                                text: parent.modelData
                                color: row.isCapturing ? Appearance.colors.primary : Appearance.colors.text
                                font.pixelSize: Appearance.font.size.small
                                font.bold: true
                            }
                        }
                    }
                }

                RetroButton {
                    text: row.isCapturing ? "BATAL" : "UBAH"
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
        title: "file keybind (pola jakoolit)"
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.normal
        implicitHeight: files.implicitHeight + Appearance.spacing.large * 2
        color: Appearance.colors.background
        border.width: Appearance.border.thin
        border.color: Appearance.colors.outline

        StyledText {
            id: files

            anchors.fill: parent
            anchors.margins: Appearance.spacing.large
            textFormat: Text.PlainText
            color: Appearance.colors.textDim
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

        RetroButton {
            text: "RESET KE DEFAULT"
            onClicked: Keybinds.resetAll()
        }
    }
}
