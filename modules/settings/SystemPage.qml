import QtQuick
import QtQuick.Layouts
import qs.services
import qs.utils

ColumnLayout {
    spacing: 2

    // Menit idle; 0 ditampilkan sebagai "mati"
    component Minutes: SettingStepper {
        from: 0
        to: 60
        stepSize: 5
        labelWidth: 80
        format: v => v === 0 ? "mati" : `${v} mnt`
    }

    SettingSection {
        Layout.topMargin: 0
        title: "Idle"
    }

    SettingRow {
        label: "Kunci layar"
        description: "Setelah sekian menit tanpa input. Kafein menahan semua aksi idle"

        Minutes {
            value: Config.idleLockMinutes
            onPicked: v => Config.set("idleLockMinutes", v)
        }
    }

    SettingRow {
        label: "Matikan layar"

        Minutes {
            value: Config.idleScreenOffMinutes
            onPicked: v => Config.set("idleScreenOffMinutes", v)
        }
    }

    SettingRow {
        label: "Suspend"

        Minutes {
            value: Config.idleSuspendMinutes
            onPicked: v => Config.set("idleSuspendMinutes", v)
        }
    }

    SettingRow {
        label: "Tahan saat media diputar"
        description: "Layar tidak terkunci atau mati selama lagu/video jalan"

        SettingToggle {
            checked: Config.idleInhibitMedia
            onToggled: v => Config.set("idleInhibitMedia", v)
        }
    }

    SettingSection {
        title: "Lampu malam"
    }

    SettingRow {
        label: "Suhu warna"
        description: NightLight.available ? "Makin kecil makin hangat" : "hyprsunset belum terinstall"

        SettingStepper {
            from: 2500
            to: 6000
            stepSize: 250
            labelWidth: 80
            unit: " K"
            value: Config.nightLightTemp
            onPicked: v => Config.set("nightLightTemp", v)
        }
    }

    SettingSection {
        title: "Tangkap layar"
    }

    SettingRow {
        label: "Folder screenshot"

        SettingText {
            value: Config.raw("screenshotDir")
            onCommitted: v => Config.set("screenshotDir", v.trim() || "~/Pictures/Screenshots")
        }
    }

    SettingRow {
        label: "Folder rekaman"
        description: Recorder.available ? "" : "wf-recorder belum terinstall"

        SettingText {
            value: Config.raw("recordingDir")
            onCommitted: v => Config.set("recordingDir", v.trim() || "~/Videos/Recordings")
        }
    }

    SettingRow {
        label: "Rekam suara"
        description: "Ikut merekam audio dari output default"

        SettingToggle {
            checked: Config.recordAudio
            onToggled: v => Config.set("recordAudio", v)
        }
    }

    SettingSection {
        title: "Clipboard"
    }

    SettingRow {
        label: "Riwayat clipboard"
        description: Clipboard.available ? "Buka dengan ; di launcher" : "cliphist belum terinstall"

        SettingToggle {
            checked: Config.clipboardHistory
            onToggled: v => Config.set("clipboardHistory", v)
        }
    }

    SettingSection {
        title: "Update"
    }

    SettingRow {
        label: "Cek update paket"
        description: Updates.available ? (Updates.count > 0 ? `${Updates.count} paket bisa diperbarui` : "Tiap jam lewat " + (Updates.manager === "dnf" ? "dnf" : "checkupdates")) : "Butuh dnf atau pacman-contrib (checkupdates)"

        SettingToggle {
            checked: Config.updateCheck
            onToggled: v => Config.set("updateCheck", v)
        }
    }
}
