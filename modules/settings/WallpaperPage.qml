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
        title: `Pilih wallpaper (${walls.count})`
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

            StyledClippingRect {
                anchors.fill: parent
                anchors.margins: Appearance.spacing.small / 2 + 1
                radius: cell.isCurrent ? Appearance.radius.large : Appearance.radius.small
                color: Appearance.colors.surfaceContainerHigh
                scale: mouse.containsMouse ? 1.03 : 1

                Behavior on radius {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
                }
                Behavior on scale {
                    Anim {
                        duration: Appearance.anim.durations.small
                    }
                }

                Image {
                    anchors.fill: parent
                    source: `file://${cell.filePath}`
                    sourceSize: Qt.size(256, 160)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                StyledRect {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Appearance.spacing.small
                    width: 28
                    height: 28
                    radius: Appearance.radius.normal
                    color: Appearance.colors.primary
                    scale: cell.isCurrent ? 1 : 0

                    Behavior on scale {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveFast
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "check"
                        font.pixelSize: Appearance.font.size.larger
                        color: Appearance.colors.primaryText
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
        text: "Tidak ada gambar di folder ini"
        color: Appearance.colors.textDim
    }

    SettingRow {
        label: "Palet hasil matugen"
        description: "Berubah otomatis setiap ganti wallpaper"

        ColorSwatches {}
    }
}
