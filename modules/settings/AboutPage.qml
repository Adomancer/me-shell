import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    spacing: Appearance.spacing.large

    component Key: StyledText {
        Layout.preferredWidth: 96
        color: Appearance.colors.textDim
    }

    component Value: StyledText {
        Layout.fillWidth: true
        font.family: Appearance.font.family.mono
        elide: Text.ElideRight
    }

    RowLayout {
        spacing: Appearance.spacing.huge * 2

        // Logo: "me" mono di kotak bulat
        StyledRect {
            implicitWidth: 128
            implicitHeight: 128
            radius: Appearance.radius.large + 8
            color: Appearance.colors.primaryContainer

            StyledText {
                anchors.centerIn: parent
                text: "me"
                color: Appearance.colors.primaryContainerText
                font.family: Appearance.font.family.mono
                font.pixelSize: 56
                font.bold: true
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Appearance.spacing.normal
            rowSpacing: 4

            Key {
                text: "Versi"
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
                text: "Kernel"
            }
            Value {
                text: UserInfo.kernel
            }
            Key {
                text: "Config"
            }
            Value {
                text: Paths.config
            }
            Key {
                text: "Repo"
            }
            Value {
                text: "github.com/Adomancer/me-shell"
            }
            Key {
                text: "Lisensi"
            }
            Value {
                text: "GPL-3.0"
            }
        }
    }

    SettingSection {
        title: "Terinspirasi dari"
    }

    StyledText {
        Layout.fillWidth: true
        text: "Caelestia (struktur drawer, animasi, popout, lockscreen bento, prompt starship, gaya terminal), end-4 (jendela settings), JaKooLit (keybind dan pembagian file Hyprland), Material Design 3 (kurva animasi dan peran warna), Nothing dan Teenage Engineering (gaya visual; tidak berafiliasi)"
        color: Appearance.colors.textDim
        wrapMode: Text.Wrap
    }
}
