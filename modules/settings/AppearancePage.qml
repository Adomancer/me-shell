import QtQuick
import QtQuick.Layouts
import qs.services
import qs.utils

ColumnLayout {
    spacing: 2

    SettingSection {
        Layout.topMargin: 0
        title: "Tema"
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
        label: "Font teks"
        description: "Font untuk sebagian besar teks; harus sudah terinstall"

        SettingCycle {
            labelWidth: 160
            options: ["Space Grotesk", "Rubik", "Inter", "Noto Sans"]
            value: Config.fontSans
            onPicked: v => Config.set("fontSans", v)
        }
    }

    SettingRow {
        label: "Font label"
        description: "Font monospace untuk label kecil dan angka"

        SettingCycle {
            labelWidth: 160
            options: ["Space Mono", "JetBrains Mono", "IBM Plex Mono", "Fira Code"]
            value: Config.fontFamily
            onPicked: v => Config.set("fontFamily", v)
        }
    }

    SettingRow {
        label: "Font angka besar"
        description: "Jam dan persen utama; Doto = dot-matrix"

        SettingCycle {
            labelWidth: 160
            options: ["Doto", "Space Mono", "JetBrains Mono"]
            value: Config.fontDisplay
            onPicked: v => Config.set("fontDisplay", v)
        }
    }

    SettingRow {
        label: "Palet aktif"
        description: "Dari wallpaper lewat matugen"

        ColorSwatches {}
    }

    SettingSection {
        title: "Efek"
    }

    SettingRow {
        label: "Bingkai layar"
        description: "Bingkai di sekeliling layar tempat panel menempel"

        SettingToggle {
            checked: Config.frameEnabled
            onToggled: v => Config.set("frameEnabled", v)
        }
    }

    SettingRow {
        label: "Tebal bingkai"

        SettingStepper {
            from: 4
            to: 20
            stepSize: 2
            unit: "px"
            value: Config.frameThickness
            onPicked: v => Config.set("frameThickness", v)
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
