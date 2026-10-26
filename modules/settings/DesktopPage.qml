import QtQuick
import QtQuick.Layouts
import qs.utils

ColumnLayout {
    spacing: 2

    SettingSection {
        Layout.topMargin: 0
        title: "Jam"
    }

    SettingRow {
        label: "Jam desktop"
        description: "Jam besar, tanggal, dan cuaca di atas wallpaper"

        SettingToggle {
            checked: Config.desktopClock
            onToggled: v => Config.set("desktopClock", v)
        }
    }

    SettingRow {
        label: "Posisi jam"

        SettingCycle {
            options: ["kiri bawah", "kanan bawah", "kiri atas", "tengah"]
            value: Config.desktopClockPosition
            onPicked: v => Config.set("desktopClockPosition", v)
        }
    }

    SettingSection {
        title: "Visualizer"
    }

    SettingRow {
        label: "Visualizer desktop"
        description: "Batang cava di dasar layar, hanya saat lagu diputar"

        SettingToggle {
            checked: Config.desktopVisualizer
            onToggled: v => Config.set("desktopVisualizer", v)
        }
    }
}
