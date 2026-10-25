import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    spacing: Appearance.spacing.large

    component Key: StyledText {
        Layout.preferredWidth: 96
        color: Appearance.colors.primary
        font.pixelSize: Appearance.font.size.small
        font.bold: true
    }

    component Value: StyledText {
        Layout.fillWidth: true
        elide: Text.ElideRight
    }

    RowLayout {
        spacing: Appearance.spacing.huge * 2

        StyledText {
            textFormat: Text.PlainText
            color: Appearance.colors.primary
            lineHeight: 0.9
            text: "███╗   ███╗███████╗\n████╗ ████║██╔════╝\n██╔████╔██║█████╗\n██║╚██╔╝██║██╔══╝\n██║ ╚═╝ ██║███████╗\n╚═╝     ╚═╝╚══════╝"
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Appearance.spacing.normal
            rowSpacing: 4

            Key {
                text: "VERSI"
            }
            Value {
                text: "0.1.0"
            }
            Key {
                text: "OS"
            }
            Value {
                text: UserInfo.distro
            }
            Key {
                text: "KERNEL"
            }
            Value {
                text: UserInfo.kernel
            }
            Key {
                text: "CONFIG"
            }
            Value {
                text: Paths.config
            }
            Key {
                text: "REPO"
            }
            Value {
                text: "github.com/Adomancer/me-shell"
            }
        }
    }

    SettingSection {
        title: "terinspirasi dari"
    }

    StyledText {
        Layout.fillWidth: true
        text: "Caelestia (tata letak), end_4 (settings), JaKooLit (keybind)"
        color: Appearance.colors.textDim
        wrapMode: Text.Wrap
    }
}
