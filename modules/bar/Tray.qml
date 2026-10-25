import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.components
import qs.utils

StyledRect {
    id: root

    property var window
    readonly property int count: items.count

    implicitWidth: row.implicitWidth + Appearance.padding.small * 2
    implicitHeight: Config.barHeight - 10
    radius: height / 2
    color: Appearance.colors.surfaceContainer

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Repeater {
            id: items

            model: SystemTray.items

            Item {
                id: item

                required property SystemTrayItem modelData

                implicitWidth: 26
                implicitHeight: 26

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 16
                    source: item.modelData.icon
                    asynchronous: true
                }

                StateLayer {
                    radius: height / 2
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton && !item.modelData.onlyMenu) {
                            item.modelData.activate();
                        } else if (item.modelData.hasMenu && root.window) {
                            const p = item.mapToItem(null, 0, item.height + Appearance.spacing.small);
                            item.modelData.display(root.window, p.x, p.y);
                        }
                    }
                }
            }
        }
    }
}
