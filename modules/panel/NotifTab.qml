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

    // Kepala: jumlah dot-matrix, jangan ganggu, hapus semua
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        DisplayText {
            text: String(Math.min(Notifs.list.length, 99)).padStart(2, "0")
            weight: 800
            color: Notifs.list.length > 0 ? Appearance.colors.primary : Appearance.colors.outline
            font.pixelSize: 34
        }

        Caption {
            Layout.fillWidth: true
            text: "Notifikasi"
        }

        Caption {
            text: "Jangan ganggu"
            color: Notifs.dnd ? Appearance.colors.primary : Appearance.colors.textDim
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

    Divider {}

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
            values: Object.keys(Notifs.groups)
        }

        delegate: Column {
            id: group

            required property string modelData
            readonly property var items: Notifs.groups[modelData] ?? []
            property bool expanded: false

            width: ListView.view.width
            spacing: Appearance.spacing.small

            RowLayout {
                width: parent.width
                spacing: Appearance.spacing.small

                AppIcon {
                    readonly property string appIcon: group.items[0]?.appIcon ?? ""

                    visible: appIcon !== ""
                    size: 18
                    source: appIcon ? Quickshell.iconPath(appIcon, true) : ""
                }

                Caption {
                    text: group.modelData
                    color: Appearance.colors.text
                }

                StyledText {
                    text: String(group.items.length).padStart(2, "0")
                    color: Appearance.colors.outline
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
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

            DisplayText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "00"
                weight: 800
                color: Appearance.colors.outline
                font.pixelSize: 64
            }

            Caption {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Notifs.dnd ? "Jangan ganggu aktif" : "Semua beres"
            }
        }
    }
}
