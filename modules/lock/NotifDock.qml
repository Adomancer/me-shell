import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import qs.modules.notifs

// Notifikasi yang masuk selama layar terkunci
Card {
    id: root

    title: "Notifikasi"
    icon: "notifications"
    note: Notifs.list.length > 0 ? Notifs.list.length : ""
    color: Appearance.alpha(Appearance.colors.surfaceContainer, 0.85)
    // Tinggi diatur layout (fillHeight); nilai tetap supaya tidak binding loop
    implicitHeight: 160

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: root.height - 64
        clip: true
        spacing: Appearance.spacing.small
        interactive: contentHeight > height

        model: ScriptModel {
            values: [...Notifs.list].reverse()
        }

        delegate: NotifCard {
            required property var modelData

            width: ListView.view.width
            notif: modelData
            background: Appearance.colors.surfaceContainerHigh
        }

        add: Transition {
            Anim {
                property: "opacity"
                from: 0
                to: 1
            }
        }

        Column {
            anchors.centerIn: parent
            visible: list.count === 0
            spacing: Appearance.spacing.small

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "notifications_paused"
                font.pixelSize: 40
                color: Appearance.colors.outline
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Tidak ada notifikasi"
                color: Appearance.colors.textDim
            }
        }
    }
}
