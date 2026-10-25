import QtQuick
import QtQuick.Layouts
import qs.services
import qs.utils

ColumnLayout {
    spacing: 0

    SettingSection {
        Layout.topMargin: 0
        title: "tema"
    }

    SettingRow {
        label: "Mode warna"
        description: "Diteruskan ke matugen; warna dibuat ulang dari wallpaper aktif"

        SettingCycle {
            options: ["dark", "light"]
            value: Config.colorMode
            onPicked: v => {
                Config.set("colorMode", v);
                if (Wallpaper.current)
                    Wallpaper.set(Wallpaper.current);
            }
        }
    }

    SettingRow {
        label: "Font"
        description: "Font monospace untuk semua teks; harus sudah terinstall"

        SettingCycle {
            labelWidth: 160
            options: ["JetBrains Mono", "Departure Mono", "IBM Plex Mono", "Fira Code"]
            value: Config.fontFamily
            onPicked: v => Config.set("fontFamily", v)
        }
    }

    SettingRow {
        label: "Palet aktif"
        description: "Dari wallpaper lewat matugen"

        ColorSwatches {}
    }

    SettingSection {
        title: "efek retro"
    }

    SettingRow {
        label: "Pixel art"
        description: "Cover album dan avatar dibuat kotak-kotak"

        SettingToggle {
            checked: Config.pixelArt
            onToggled: v => Config.set("pixelArt", v)
        }
    }

    SettingRow {
        label: "Shader CRT di lockscreen"
        description: "Jalankan scripts/build-shaders.sh dulu"

        SettingToggle {
            checked: Config.crtShader
            onToggled: v => Config.set("crtShader", v)
        }
    }

    SettingRow {
        label: "Kecepatan animasi"
        description: "Semua durasi animasi ikut berubah"

        SettingCycle {
            options: ["cepat", "normal", "lambat"]
            value: Config.animSpeed
            onPicked: v => Config.set("animSpeed", v)
        }
    }
}
