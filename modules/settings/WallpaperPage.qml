import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    spacing: 0

    SettingRow {
        label: "Folder wallpaper"
        description: "jpg, jpeg, png, webp"

        SettingText {
            value: Config.raw("wallpaperDir")
            onCommitted: v => Config.set("wallpaperDir", v || "~/Pictures/Wallpapers")
        }
    }

    SettingRow {
        label: "Wallpaper dari shell"
        description: "Matikan kalau pakai swww atau hyprpaper"

        SettingToggle {
            checked: Config.renderWallpaper
            onToggled: v => Config.set("renderWallpaper", v)
        }
    }

    SettingSection {
        title: `pilih wallpaper (${walls.count})`
    }

    FolderListModel {
        id: walls

        folder: `file://${Config.wallpaperDir}`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    GridView {
        id: grid

        readonly property int columns: 4

        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.normal
        Layout.preferredHeight: Math.ceil(count / columns) * cellHeight
        interactive: false
        model: walls
        cellWidth: width / columns
        cellHeight: cellWidth * 10 / 16

        delegate: Item {
            id: cell

            required property string filePath
            readonly property bool isCurrent: filePath === Wallpaper.current

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: Appearance.spacing.small
                color: Appearance.colors.surfaceHigh
                border.width: Appearance.border.normal
                border.color: cell.isCurrent ? Appearance.colors.primary : mouse.containsMouse ? Appearance.colors.textDim : Appearance.colors.outline

                Image {
                    anchors.fill: parent
                    anchors.margins: Appearance.border.normal
                    source: `file://${cell.filePath}`
                    sourceSize: Qt.size(256, 160)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Rectangle {
                    visible: cell.isCurrent
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: Appearance.spacing.small
                    implicitWidth: tag.implicitWidth + 8
                    implicitHeight: tag.implicitHeight
                    color: Appearance.colors.primary

                    StyledText {
                        id: tag

                        anchors.centerIn: parent
                        text: "AKTIF"
                        color: Appearance.colors.primaryText
                        font.pixelSize: Appearance.font.size.small
                        font.bold: true
                    }
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpaper.set(cell.filePath)
                }
            }
        }
    }

    StyledText {
        visible: walls.count === 0
        Layout.topMargin: Appearance.spacing.normal
        text: "-- tidak ada gambar di folder ini --"
        color: Appearance.colors.textDim
    }

    SettingRow {
        label: "Palet hasil matugen"
        description: "Berubah otomatis setiap ganti wallpaper"

        ColorSwatches {}
    }
}
