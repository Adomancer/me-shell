import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import qs.modules.notifs

ColumnLayout {
    spacing: Appearance.spacing.normal

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: `NOTIF (${Notifs.list.length})`
            font.bold: true
        }

        RetroButton {
            text: `${Notifs.dnd ? "[x]" : "[ ]"} DND`
            active: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }

        RetroButton {
            visible: Notifs.list.length > 0
            text: "CLEAR"
            onClicked: Notifs.clearAll()
        }
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Appearance.spacing.normal

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
        }
    }
}
