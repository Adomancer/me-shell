import Quickshell
import Quickshell.Widgets
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

        // Satu baris per aplikasi, urut dari notifikasi terbaru. Nilainya string, jadi delegate tetap
        // sama saat notifikasi dalam grup bertambah/berkurang.
        model: ScriptModel {
            values: [...new Set([...Notifs.list].reverse().map(n => n.appName || "Lainnya"))]
        }

        delegate: Column {
            id: group

            required property string modelData
            readonly property var items: [...Notifs.list].reverse().filter(n => (n.appName || "Lainnya") === modelData)
            property bool expanded: false

            width: ListView.view.width
            spacing: Appearance.spacing.small

            RowLayout {
                width: parent.width
                spacing: Appearance.spacing.small

                IconImage {
                    readonly property string icon: group.items[0]?.appIcon ?? ""

                    visible: icon !== ""
                    implicitSize: 18
                    source: icon ? Quickshell.iconPath(icon, true) : ""
                    asynchronous: true
                }

                StyledText {
                    text: group.modelData
                    color: Appearance.colors.primary
                    font.weight: Font.Medium
                }

                StyledRect {
                    implicitWidth: Math.max(implicitHeight, groupCount.implicitWidth + 10)
                    implicitHeight: 18
                    radius: height / 2
                    color: Appearance.colors.secondaryContainer

                    StyledText {
                        id: groupCount

                        anchors.centerIn: parent
                        text: group.items.length
                        color: Appearance.colors.secondaryContainerText
                        font.family: Appearance.font.family.mono
                        font.pixelSize: Appearance.font.size.small
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                IconButton {
                    visible: group.items.length > 1
                    icon: group.expanded ? "expand_less" : "expand_more"
                    onClicked: group.expanded = !group.expanded
                }

                IconButton {
                    icon: "clear_all"
                    onClicked: {
                        for (const n of group.items)
                            n.dismiss();
                    }
                }
            }

            // Tertutup: hanya yang terbaru; terbuka: semua
            Repeater {
                model: ScriptModel {
                    values: group.expanded ? group.items : group.items.slice(0, 1)
                }

                NotifCard {
                    required property var modelData

                    width: group.width
                    notif: modelData
                }
            }

            TextButton {
                visible: !group.expanded && group.items.length > 1
                type: "text"
                icon: "unfold_more"
                text: `${group.items.length - 1} lainnya`
                onClicked: group.expanded = true
            }
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
