import QtQuick
import QtQuick.Layouts
import qs.services
import qs.utils

ColumnLayout {
    spacing: 2

    SettingSection {
        Layout.topMargin: 0
        title: "Cuaca"
    }

    SettingRow {
        label: "Lokasi"
        description: "Nama kota untuk wttr.in; kosong = otomatis dari IP"

        SettingText {
            value: Config.weatherLocation
            placeholder: "otomatis"
            onCommitted: v => Config.set("weatherLocation", v.trim())
        }
    }

    SettingSection {
        title: "Notifikasi"
    }

    SettingRow {
        label: "Durasi popup"
        description: "Notifikasi kritis tidak hilang sendiri"

        SettingStepper {
            from: 2
            to: 15
            unit: " dtk"
            value: Config.notifTimeout
            onPicked: v => Config.set("notifTimeout", v)
        }
    }

    SettingRow {
        label: "Jangan ganggu"
        description: "Popup disembunyikan, riwayat tetap tersimpan"

        SettingToggle {
            checked: Notifs.dnd
            onToggled: v => Notifs.dnd = v
        }
    }

    SettingRow {
        label: "Popup saat fullscreen"
        description: "Mati = popup ditahan selama game/video fullscreen, tetap masuk riwayat"

        SettingToggle {
            checked: Config.notifsInFullscreen
            onToggled: v => Config.set("notifsInFullscreen", v)
        }
    }

    SettingSection {
        title: "Audio"
    }

    SettingRow {
        label: "Visualizer (cava)"
        description: Cava.available ? "Equalizer di tab MEDIA" : "cava belum terinstall"

        SettingToggle {
            checked: Config.cavaEnabled
            onToggled: v => Config.set("cavaEnabled", v)
        }
    }

    SettingSection {
        title: "Jaringan"
    }

    SettingRow {
        label: "Wi-Fi"
        description: Network.connected ? `Terhubung ke ${Network.ssid}` : "nmcli radio wifi"

        SettingToggle {
            checked: Network.wifiEnabled
            onToggled: v => Network.setWifi(v)
        }
    }

    SettingRow {
        label: "Bluetooth"
        description: BluetoothService.available ? `${BluetoothService.devices.length} perangkat terhubung` : "Tidak ada adapter Bluetooth"

        SettingToggle {
            enabled: BluetoothService.available
            checked: BluetoothService.enabled
            onToggled: BluetoothService.toggle()
        }
    }
}
