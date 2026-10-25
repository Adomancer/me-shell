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
        spacing: Appearance.spacing.normal

        StyledText {
            text: "Notifikasi"
            font.pixelSize: Appearance.font.size.large
            font.weight: Font.Medium
        }

        StyledText {
            Layout.fillWidth: true
            text: Notifs.list.length > 0 ? Notifs.list.length : ""
            color: Appearance.colors.textDim
            font.family: Appearance.font.family.mono
        }

        StyledText {
            text: "Jangan ganggu"
            color: Appearance.colors.textDim
        }

        StyledSwitch {
            checked: Notifs.dnd
            onToggled: v => Notifs.dnd = v
        }

        TextButton {
            Layout.leftMargin: Appearance.spacing.normal
            visible: Notifs.list.length > 0
            icon: "clear_all"
            text: "Hapus semua"
            onClicked: Notifs.clearAll()
        }
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Appearance.spacing.normal
        boundsBehavior: Flickable.StopAtBounds

        model: ScriptModel {
            values: [...Notifs.list].reverse()
        }

        delegate: NotifCard {
            required property var modelData

            width: ListView.view.width
            notif: modelData
        }

        add: Transition {
            Anim {
                property: "opacity"
                from: 0
                to: 1
            }
            Anim {
                property: "scale"
                from: 0.9
                to: 1
                easing.bezierCurve: Appearance.anim.curves.expressiveDefault
            }
        }

        remove: Transition {
            Anim {
                property: "x"
                to: list.width
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
            Anim {
                property: "opacity"
                to: 0
            }
        }

        displaced: Transition {
            Anim {
                property: "y"
                duration: Appearance.anim.durations.expressiveDefault
                easing.bezierCurve: Appearance.anim.curves.expressiveDefault
            }
            // Item yang tergeser di tengah animasi masuk langsung dirapikan
            Anim {
                properties: "opacity,scale"
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
                font.pixelSize: 56
                color: Appearance.colors.outline
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Semua sudah terbaca"
                color: Appearance.colors.textDim
            }
        }
    }
}
