import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Info sistem ala neofetch
Card {
    component Key: Row {
        property string icon
        property string label

        Layout.preferredWidth: 96
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.icon
            font.pixelSize: Appearance.font.size.larger
            color: Appearance.colors.primary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: Appearance.colors.textDim
        }
    }

    component Value: StyledText {
        Layout.fillWidth: true
        font.family: Appearance.font.family.mono
        font.pixelSize: Appearance.font.size.smaller
        elide: Text.ElideRight
    }

    title: "Sistem"
    icon: "terminal"
    note: `${UserInfo.user}@${UserInfo.host}`
    color: Appearance.alpha(Appearance.colors.surfaceContainer, 0.85)

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Appearance.spacing.normal
        rowSpacing: 4

        Key {
            icon: "computer"
            label: "OS"
        }
        Value {
            text: UserInfo.distro
        }
        Key {
            icon: "grid_view"
            label: "WM"
        }
        Value {
            text: UserInfo.wm
        }
        Key {
            icon: "deployed_code"
            label: "Kernel"
        }
        Value {
            text: UserInfo.kernel
        }
        Key {
            icon: "schedule"
            label: "Uptime"
        }
        Value {
            text: UserInfo.uptime
        }
        Key {
            icon: "package_2"
            label: "Paket"
        }
        Value {
            text: UserInfo.packages
        }
    }
}
