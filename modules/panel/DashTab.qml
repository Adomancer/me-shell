import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherIcons.js" as WeatherIcons

// Tab Dashboard ala Nothing/TE, tanpa kartu: jam dot-matrix besar + cuaca + user di kiri, kalender di
// tengah, lagu di kanan, dipisah garis tipis. Di bawah: slider bersegmen dan toggle bulat.
ColumnLayout {
    id: root

    // "12:06" -> ["12", "06"]; titik dua berkedip seperti jam di bar
    readonly property var parts: Qt.formatDateTime(Time.date, "hh:mm").split(":")
    property bool tick: true
    // Bagian hari yang sudah lewat (0..1)
    readonly property real dayProgress: (Time.date.getHours() * 60 + Time.date.getMinutes()) / 1440

    spacing: Appearance.spacing.large

    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        onTriggered: root.tick = !root.tick
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.huge

        // Kiri: jam, tanggal, cuaca, user
        ColumnLayout {
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            spacing: Appearance.spacing.small

            Caption {
                text: Time.date.toLocaleString(Qt.locale(), "dddd")
                color: Appearance.colors.primary
            }

            Row {
                DisplayText {
                    text: root.parts[0]
                    font.pixelSize: 88
                }

                DisplayText {
                    text: ":"
                    color: Appearance.colors.primary
                    font.pixelSize: 88
                    opacity: root.tick ? 1 : 0.15

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }
                }

                DisplayText {
                    text: root.parts[1]
                    font.pixelSize: 88
                }
            }

            StyledText {
                text: Time.date.toLocaleString(Qt.locale(), "d MMMM yyyy")
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.larger
            }

            // Progres hari ala TE
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.large

                Caption {
                    Layout.fillWidth: true
                    text: "Hari ini"
                }

                StyledText {
                    text: `${Math.round(root.dayProgress * 100)}%`
                    color: Appearance.colors.textDim
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
                }
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
