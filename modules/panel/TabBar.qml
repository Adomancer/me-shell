import QtQuick
import qs.components
import qs.services
import qs.utils

// Tab ala Nothing/TE: nomor + label mono, pil aksen kecil di bawah yang melar saat berpindah.
Item {
    id: root

    property string current: ""
    readonly property var items: [
        {
            name: "dash",
            label: "Dash",
            icon: "dashboard"
        },
        {
            name: "media",
            label: "Media",
            icon: "queue_music"
        },
        {
            name: "perf",
            label: "Performa",
            icon: "monitoring"
        },
        {
            name: "weather",
            label: "Cuaca",
            icon: "partly_cloudy_day"
        },
        {
            name: "notif",
            label: "Notif",
            icon: "notifications"
        },
        {
            name: "focus",
            label: "Fokus",
            icon: "timer"
        }
    ]
    readonly property int index: Math.max(0, items.findIndex(i => i.name === current))
    readonly property real tabWidth: width / items.length
    property real lead: index
    property real trail: index

    signal selected(string name)

    implicitHeight: 52

    Behavior on lead {
        Anim {
            duration: Appearance.anim.durations.normal
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }
    Behavior on trail {
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.items

            Item {
                id: tab

                required property var modelData
                required property int index
                readonly property bool isActive: root.current === modelData.name
                readonly property color ink: isActive ? Appearance.colors.primary : Appearance.colors.textDim

                width: root.tabWidth
                height: root.height

                Row {
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(tab.index + 1).padStart(2, "0")
                        color: tab.isActive ? Appearance.colors.primary : Appearance.colors.outline
                        font.family: Appearance.font.family.mono
                        font.pixelSize: Appearance.font.size.small
                    }

                    Caption {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.label
                        color: tab.isActive ? Appearance.colors.text : Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.smaller
                    }

                    // Jumlah notifikasi: titik aksen + angka
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: tab.modelData.name === "notif" && Notifs.list.length > 0
                        spacing: 4

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: Appearance.colors.primary
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Notifs.list.length
                            color: Appearance.colors.primary
                            font.family: Appearance.font.family.mono
                            font.pixelSize: Appearance.font.size.small
                        }
                    }
                }

                StateLayer {
                    radius: Appearance.radius.small
                    onClicked: root.selected(tab.modelData.name)
                }
            }
        }
    }

    Divider {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    // Pil aksen: lebar mengikuti jarak dua ujung, jadi melar saat berpindah
    Rectangle {
        readonly property real base: 18

        anchors.bottom: parent.bottom
        anchors.bottomMargin: -1
        x: Math.min(root.lead, root.trail) * root.tabWidth + (root.tabWidth - base) / 2
        width: Math.abs(root.lead - root.trail) * root.tabWidth + base
        height: 3
        radius: 1.5
        color: Appearance.colors.primary
    }
}
