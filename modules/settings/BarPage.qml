import QtQuick
import QtQuick.Layouts
import qs.utils

ColumnLayout {
    spacing: 2

    SettingRow {
        label: "Tinggi bar"
        description: "Exclusive zone ikut menyesuaikan"

        SettingStepper {
            from: 24
            to: 48
            stepSize: 2
            unit: "px"
            value: Config.barHeight
            onPicked: v => Config.set("barHeight", v)
        }
    }

    SettingRow {
        label: "Ikon aplikasi di workspace"
        description: "Workspace yang berisi window menampilkan ikon aplikasinya, bukan nomor"

        SettingToggle {
            checked: Config.barWorkspaceIcons
            onToggled: v => Config.set("barWorkspaceIcons", v)
        }
    }

    SettingRow {
        label: "Judul window aktif"
        description: "Di sebelah workspace"

        SettingToggle {
            checked: Config.barShowTitle
            onToggled: v => Config.set("barShowTitle", v)
        }
    }

    SettingRow {
        label: "Lagu yang diputar"
        description: "Judul lagu di kanan; klik untuk putar/jeda"

        SettingToggle {
            checked: Config.barShowMedia
            onToggled: v => Config.set("barShowMedia", v)
        }
    }

    SettingRow {
        label: "Popout saat hover"
        description: "Wi-Fi, Bluetooth, suara, baterai, dan pratinjau window"

        SettingToggle {
            checked: Config.barPopouts
            onToggled: v => Config.set("barPopouts", v)
        }
    }

    SettingRow {
        label: "System tray"
        description: "Ikon aplikasi di kanan"

        SettingToggle {
            checked: Config.barShowTray
            onToggled: v => Config.set("barShowTray", v)
        }
    }
}
