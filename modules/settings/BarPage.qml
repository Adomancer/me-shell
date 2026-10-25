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
        label: "Judul window aktif"
        description: "Di sebelah workspace"

        SettingToggle {
            checked: Config.barShowTitle
            onToggled: v => Config.set("barShowTitle", v)
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
