import QtQuick
import QtQuick.Layouts
import qs.utils

ColumnLayout {
    spacing: 0

    SettingSection {
        Layout.topMargin: 0
        title: "jam & tanggal"
    }

    SettingRow {
        label: "Format jam"
        description: "Format Qt, misalnya hh:mm:ss atau h:mm AP"

        SettingText {
            value: Config.raw("clockFormat")
            onCommitted: v => Config.set("clockFormat", v || "hh:mm")
        }
    }

    SettingRow {
        label: "Format tanggal"
        description: "Tampil di bar"

        SettingText {
            value: Config.raw("dateFormat")
            onCommitted: v => Config.set("dateFormat", v || "ddd, dd MMM")
        }
    }

    SettingRow {
        label: "Kursor berkedip"
        description: "Kursor _ di sebelah jam"

        SettingToggle {
            checked: Config.blinkCursor
            onToggled: v => Config.set("blinkCursor", v)
        }
    }

    SettingSection {
        title: "workspace"
    }

    SettingRow {
        label: "Jumlah workspace"
        description: "Tombol workspace di bar"

        SettingStepper {
            from: 1
            to: 10
            value: Config.workspaces
            onPicked: v => Config.set("workspaces", v)
        }
    }

    SettingSection {
        title: "launcher"
    }

    SettingRow {
        label: "Hasil maksimal"
        description: "Jumlah aplikasi yang ditampilkan"

        SettingStepper {
            from: 4
            to: 16
            value: Config.launcherMaxResults
            onPicked: v => Config.set("launcherMaxResults", v)
        }
    }
}
