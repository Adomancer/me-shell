import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherIcons.js" as WeatherIcons

// Tab Dashboard ala Nothing/TE, tanpa kartu: sapaan + progres hari dot-matrix besar + cuaca + user di kiri
// (jam sudah ada di bar), kalender di tengah, lagu di kanan, dipisah garis tipis. Di bawah: slider bersegmen
// dan toggle bulat.
ColumnLayout {
    id: root

    // Bagian hari yang sudah lewat (0..1)
    readonly property real dayProgress: (Time.date.getHours() * 60 + Time.date.getMinutes()) / 1440

    spacing: Appearance.spacing.large

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.huge

        // Kiri: sapaan, progres hari, tanggal, cuaca, user
        ColumnLayout {
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            spacing: Appearance.spacing.small

            Caption {
                text: Time.greeting
                color: Appearance.colors.primary
            }

            // Progres hari ala TE: persen dot-matrix besar
            Row {
                spacing: Appearance.spacing.small

                DisplayText {
                    id: dayPct

                    text: String(Math.round(root.dayProgress * 100)).padStart(2, "0")
                    font.pixelSize: 88
                }

                // Doto di ukuran kecil tidak terbaca; persen pakai font mono
                StyledText {
                    anchors.baseline: dayPct.baseline
                    text: "%"
                    color: Appearance.colors.outline
                    font.family: Appearance.font.family.mono
                    font.pixelSize: 28
                }
            }

            Caption {
                text: "Hari ini sudah lewat"
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: Time.date.toLocaleString(Qt.locale(), "dddd, d MMMM yyyy")
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.larger
            }

            SegmentBar {
                Layout.fillWidth: true
                implicitHeight: 10
                segments: 24
                value: root.dayProgress
            }

            Item {
                Layout.fillHeight: true
            }

            // Cuaca satu baris
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: Weather.available ? WeatherIcons.get(Weather.kind) : "cloud_off"
                    font.pixelSize: Appearance.font.size.extraLarge
                    color: Appearance.colors.text
                }

                StyledText {
                    text: Weather.available ? `${Weather.temp}°` : "--"
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Weather.available ? `${Weather.description} · ${Weather.location}` : "Tidak ada data cuaca"
                    color: Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }

            Divider {}

            // User
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                Avatar {
                    size: 36
                    source: `file://${UserInfo.avatar}`
                    initial: UserInfo.displayName.charAt(0).toUpperCase()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: UserInfo.displayName
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Row {
                        spacing: Appearance.spacing.normal

                        Chip {
                            icon: "schedule"
                            text: UserInfo.uptime
                        }

                        Chip {
                            icon: Network.ethernet ? "lan" : Network.connected ? "wifi" : "wifi_off"
                            text: Network.ethernet ? "Ethernet" : Network.connected ? Network.ssid : "Offline"
                        }

                        // Update paket yang tersedia; klik = upgrade di terminal
                        Chip {
                            visible: Updates.count > 0
                            icon: "system_update_alt"
                            text: `${Updates.count} update`

                            StateLayer {
                                onClicked: {
                                    DrawerState.close();
                                    Updates.upgrade();
                                }
                            }
                        }
                    }
                }
            }
        }

        Divider {
            vertical: true
        }

        Calendar {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }

        Divider {
            vertical: true
        }

        NowPlaying {
            Layout.preferredWidth: 210
            Layout.fillHeight: true
            pad: 0
        }
    }

    Divider {}

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.large

        StyledSlider {
            Layout.fillWidth: true
            label: "VOL"
            showValue: true
            value: Audio.muted ? 0 : Audio.volume
            onMoved: v => Audio.setVolume(v)
        }

        StyledSlider {
            Layout.fillWidth: true
            visible: Brightness.available
            label: "LCD"
            showValue: true
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }

        IconButton {
            type: "tonal"
            icon: Network.wifiEnabled ? "wifi" : "wifi_off"
            toggled: Network.wifiEnabled
            padding: Appearance.padding.normal - 2
            onClicked: Network.setWifi(!Network.wifiEnabled)
        }

        IconButton {
            type: "tonal"
            icon: BluetoothService.enabled ? "bluetooth" : "bluetooth_disabled"
            toggled: BluetoothService.enabled
            disabled: !BluetoothService.available
            padding: Appearance.padding.normal - 2
            onClicked: BluetoothService.toggle()
        }

        IconButton {
            type: "tonal"
            icon: Notifs.dnd ? "notifications_off" : "notifications"
            toggled: Notifs.dnd
            padding: Appearance.padding.normal - 2
            onClicked: Notifs.toggleDnd()
        }

        IconButton {
            type: "tonal"
            icon: Audio.micMuted ? "mic_off" : "mic"
            toggled: !Audio.micMuted
            padding: Appearance.padding.normal - 2
            onClicked: Audio.toggleMic()
        }

        IconButton {
            type: "tonal"
            icon: "coffee"
            toggled: Idle.inhibited
            padding: Appearance.padding.normal - 2
            onClicked: Idle.toggleInhibit()
        }

        IconButton {
            type: "tonal"
            icon: "nightlight"
            toggled: NightLight.enabled
            padding: Appearance.padding.normal - 2
            onClicked: NightLight.toggle()
        }

        IconButton {
            type: "tonal"
            icon: "sports_esports"
            toggled: GameMode.enabled
            padding: Appearance.padding.normal - 2
            onClicked: GameMode.toggle()
        }

        IconButton {
            type: "tonal"
            icon: "settings"
            padding: Appearance.padding.normal - 2
            onClicked: DrawerState.open("settings")
        }
    }
}
