import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Info sistem ala neofetch
Card {
    component Key: StyledText {
        Layout.preferredWidth: 64
        color: Appearance.colors.primary
        font.pixelSize: Appearance.font.size.small
        font.bold: true
    }

    component Value: StyledText {
        Layout.fillWidth: true
        font.pixelSize: Appearance.font.size.small
        elide: Text.ElideRight
    }

    title: "fetch"
    note: `${UserInfo.user}@${UserInfo.host}`

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Appearance.spacing.normal
        rowSpacing: 2

        Key {
            text: "OS"
        }
        Value {
            text: UserInfo.distro
        }
        Key {
            text: "WM"
        }
        Value {
            text: UserInfo.wm
        }
        Key {
            text: "SHELL"
        }
        Value {
            text: "me-shell"
        }
        Key {
            text: "KERNEL"
        }
        Value {
            text: UserInfo.kernel
        }
        Key {
            text: "UPTIME"
        }
        Value {
            text: UserInfo.uptime
        }
        Key {
            text: "PKGS"
        }
        Value {
            text: UserInfo.packages
        }
    }
}
