import QtQuick
import QtQuick.Layouts
import qs.utils

ColumnLayout {
    spacing: 2

    SettingSection {
        Layout.topMargin: 0
        title: "Jam & tanggal"
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

    SettingSection {
        title: "Workspace"
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
        title: "Drawer"
    }

    SettingRow {
        label: "Buka dengan hover"
        description: "Jam = dashboard, pojok kanan bawah = utilitas, tepi kanan = slider"

        SettingToggle {
            checked: Config.hoverOpen
            onToggled: v => Config.set("hoverOpen", v)
        }
    }

    SettingSection {
        title: "Launcher"
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

    SettingSection {
        title: "Fokus"
    }

    SettingRow {
        label: "Durasi fokus"
        description: "Satu sesi pomodoro di tab FOKUS"

        SettingStepper {
            from: 5
            to: 90
            stepSize: 5
            unit: " mnt"
            value: Config.focusMinutes
            onPicked: v => Config.set("focusMinutes", v)
        }
    }

    SettingRow {
        label: "Durasi istirahat"
        description: "Mulai otomatis setelah sesi fokus selesai"

        SettingStepper {
            from: 1
            to: 30
            unit: " mnt"
            value: Config.breakMinutes
            onPicked: v => Config.set("breakMinutes", v)
        }
    }
}
