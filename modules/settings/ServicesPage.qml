import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    property bool confirmClearUsage: false

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

    SettingRow {
        label: "Lirik"
        description: "Lirik tersinkron dari lrclib.net di tab MEDIA, disimpan di cache"

        SettingToggle {
            checked: Config.lyricsEnabled
            onToggled: v => Config.set("lyricsEnabled", v)
        }
    }

    SettingSection {
        title: "Waktu penggunaan"
    }

    SettingRow {
        label: "Catat penggunaan aplikasi"
        description: "Lokal saja; hanya aplikasi fokus, tanpa judul jendela atau URL"

        SettingToggle {
            checked: Config.usageEnabled
            onToggled: v => Config.set("usageEnabled", v)
        }
    }

    SettingRow {
        label: "Batas tidak aktif"
        description: "Berhenti mencatat setelah tidak ada input; kafein tidak menahannya. Pengecualian media hanya jika opsi di bawah aktif"

        SettingStepper {
            from: 1
            to: 30
            unit: " mnt"
            value: Config.usageIdleMinutes
            onPicked: v => Config.set("usageIdleMinutes", v)
        }
    }

    SettingRow {
        label: "Hitung media aktif"
        description: "Opsional, mati secara bawaan. Hanya pemutar MPRIS yang sedang memutar dan cocok dengan aplikasi fokus yang melewati batas tidak aktif; bukan pemutaran latar belakang. Jeda pelacakan, layar terkunci, dan aplikasi dikecualikan tetap menghentikan pencatatan"

        SettingToggle {
            checked: Config.usageMediaAware === true
            onToggled: v => Config.set("usageMediaAware", v)
        }
    }

    SettingRow {
        label: "Simpan riwayat"
        description: "Data yang lebih lama dihapus otomatis; mengurangi batas menghapus data lama"

        SettingStepper {
            from: 21
            to: 365
            unit: " hari"
            value: Config.usageRetentionDays
            onPicked: v => Config.set("usageRetentionDays", v)
        }
    }

    SettingRow {
        label: "Aplikasi dikecualikan"
        description: "ID aplikasi dipisah koma, misalnya firefox, org.telegram.desktop; riwayat lama tetap ada"

        SettingText {
            value: Config.usageExcludedApps.join(", ")
            placeholder: "firefox, kitty"
            onCommitted: v => Config.set("usageExcludedApps", v.split(",").map(id => id.trim()).filter(id => id !== ""))
        }
    }

    SettingRow {
        label: "Hapus riwayat penggunaan"
        description: "Tidak dapat dibatalkan; jika pencatatan aktif, data baru akan dicatat lagi"

        TextButton {
            text: root.confirmClearUsage ? "Ya, hapus semua" : "Hapus riwayat"
            icon: "delete_outline"
            type: root.confirmClearUsage ? "filled" : "tonal"
            onClicked: {
                if (root.confirmClearUsage) {
                    Usage.clearHistory();
                    root.confirmClearUsage = false;
                    clearConfirmation.stop();
                } else {
                    root.confirmClearUsage = true;
                    clearConfirmation.restart();
                }
            }
        }
    }

    Timer {
        id: clearConfirmation
        interval: 5000
        onTriggered: root.confirmClearUsage = false
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
