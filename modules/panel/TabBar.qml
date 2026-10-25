import QtQuick
import qs.components
import qs.services
import qs.utils

// Tab Material 3: ikon + label, indikator di bawah yang meluncur dan sedikit melar saat pindah.
Item {
    id: root

    property string current: ""
    readonly property var items: [
        {
            name: "dash",
            label: "Dashboard",
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
            label: "Notifikasi",
            icon: "notifications"
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

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.icon
                        fill: tab.isActive ? 1 : 0
                        color: tab.ink
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.label
                        color: tab.ink
                        font.weight: tab.isActive ? Font.DemiBold : Font.Normal
                    }

                    // Jumlah notifikasi
                    StyledRect {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: tab.modelData.name === "notif" && Notifs.list.length > 0
                        implicitWidth: Math.max(implicitHeight, count.implicitWidth + 10)
                        implicitHeight: 18
                        radius: height / 2
                        color: Appearance.colors.error

                        StyledText {
                            id: count

                            anchors.centerIn: parent
                            text: Notifs.list.length
                            color: Appearance.colors.errorText
                            font.family: Appearance.font.family.mono
                            font.pixelSize: Appearance.font.size.small
                            font.bold: true
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

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Appearance.colors.outlineVariant
    }

    // Indikator: lebar mengikuti jarak dua ujung, jadi melar saat berpindah
    Rectangle {
        readonly property real inset: root.tabWidth * 0.22

        anchors.bottom: parent.bottom
        x: Math.min(root.lead, root.trail) * root.tabWidth + inset
        width: Math.abs(root.lead - root.trail) * root.tabWidth + root.tabWidth - inset * 2
        height: 3
        topLeftRadius: 3
        topRightRadius: 3
        color: Appearance.colors.primary
    }
}
