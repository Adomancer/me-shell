import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.utils

Row {
    id: root

    property var window

    spacing: Appearance.spacing.normal

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            implicitWidth: 16
            implicitHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                    modelData.activate();
                } else if (modelData.hasMenu && root.window) {
                    const p = item.mapToItem(null, 0, item.height + Appearance.spacing.small);
                    modelData.display(root.window, p.x, p.y);
                }
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
                asynchronous: true
            }
        }
    }
}
