import QtQuick
import qs.components
import qs.services
import qs.utils
import "../../utils/PixelIcons.js" as Icons

Item {
    id: root

    property string current: ""
    readonly property var items: [
        {
            name: "dash",
            label: "DASH",
            icon: Icons.tabDash
        },
        {
            name: "media",
            label: "MEDIA",
            icon: Icons.tabMedia
        },
        {
            name: "perf",
            label: "PERF",
            icon: Icons.tabPerf
        },
        {
            name: "weather",
            label: "CUACA",
            icon: Icons.tabWeather
        },
        {
            name: "notif",
            label: "NOTIF",
            icon: Icons.tabNotif
        }
    ]

    signal selected(string name)

    implicitHeight: 36

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Appearance.border.normal
        color: Appearance.colors.outline
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.items

            StyledRect {
                id: tabBtn

                required property var modelData
                required property int index
                readonly property bool isActive: root.current === modelData.name
                readonly property color ink: isActive ? Appearance.colors.primaryText : mouse.containsMouse ? Appearance.colors.text : Appearance.colors.textDim

                width: root.width / root.items.length
                height: root.height - Appearance.border.normal
                radius: 0
                color: isActive ? Appearance.colors.primary : mouse.containsMouse ? Appearance.colors.surfaceHigh : "transparent"

                Row {
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.normal

                    PixelIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        rows: tabBtn.modelData.icon
                        pixel: 2
                        color: tabBtn.ink
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tabBtn.modelData.label
                        color: tabBtn.ink
                        font.pixelSize: Appearance.font.size.small
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    // Jumlah notifikasi
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: tabBtn.modelData.name === "notif" && Notifs.list.length > 0
                        implicitWidth: count.implicitWidth + 8
                        implicitHeight: count.implicitHeight
                        radius: Appearance.radius.small
                        color: Appearance.colors.error

                        StyledText {
                            id: count

                            anchors.centerIn: parent
                            text: Notifs.list.length
                            color: Appearance.colors.primaryText
                            font.pixelSize: Appearance.font.size.small
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    width: Appearance.border.thin
                    height: parent.height
                    visible: tabBtn.index < root.items.length - 1
                    color: Appearance.colors.outline
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(tabBtn.modelData.name)
                }
            }
        }
    }
}
