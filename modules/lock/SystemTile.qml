import QtQuick
import qs.components
import qs.services
import qs.utils

// Info sistem ala neofetch: label kecil di kiri, nilai mono di kanan.
Tile {
    id: root

    readonly property var rows: [
        ["OS", UserInfo.distro],
        ["Kernel", UserInfo.kernel],
        ["Uptime", UserInfo.uptime],
        ["Paket", UserInfo.packages],
        ...(Battery.available ? [["Baterai", `${Math.round(Battery.percentage * 100)}%${Battery.charging ? " +" : ""}`]] : [])
    ]

    Caption {
        id: title

        anchors.left: parent.left
        anchors.top: parent.top
        text: `${UserInfo.user}@${UserInfo.host}`
        color: Appearance.colors.primary
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.topMargin: Appearance.spacing.normal
        anchors.bottom: parent.bottom

        Repeater {
            model: root.rows

            Item {
                required property var modelData

                width: parent.width
                height: parent.height / root.rows.length

                Caption {
                    id: key

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 64
                    text: parent.modelData[0]
                }

                StyledText {
                    anchors.left: key.right
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: parent.modelData[1] || "-"
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.smaller
                    elide: Text.ElideRight
                }
            }
        }
    }
}
