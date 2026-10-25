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

    title: `notif (${Notifs.list.length})`
    // Tinggi diatur layout (fillHeight); nilai tetap supaya tidak binding loop
    implicitHeight: 160

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: root.height - 56
        clip: true
        spacing: Appearance.spacing.normal
        interactive: contentHeight > height

        model: ScriptModel {
            values: [...Notifs.list].reverse()
        }

        delegate: NotifCard {
            required property var modelData

            width: ListView.view.width
            notif: modelData
        }

        StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "-- KOSONG --"
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.small
        }
    }
}
