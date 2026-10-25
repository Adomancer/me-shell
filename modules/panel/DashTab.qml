import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherIcons.js" as WeatherIcons

// Tab Dashboard ala Caelestia: user + cuaca di atas, jam + kalender + cincin resource di tengah,
// lagu di kanan, lalu kontrol cepat.
ColumnLayout {
    id: root

    spacing: Appearance.spacing.normal

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.normal

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                // User
                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        spacing: Appearance.spacing.large

                        Avatar {
                            size: 72
                            source: `file://${UserInfo.avatar}`
                            initial: UserInfo.displayName.charAt(0).toUpperCase()
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            StyledText {
                                Layout.fillWidth: true
                                text: UserInfo.displayName
                                font.pixelSize: Appearance.font.size.large
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: `${UserInfo.wm} · ${UserInfo.distro}`
                                color: Appearance.colors.textDim
                                font.pixelSize: Appearance.font.size.small
                                elide: Text.ElideRight
                            }

                            Row {
                                spacing: Appearance.spacing.small

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

                // Cuaca
                Card {
                    Layout.preferredWidth: 236
                    Layout.fillHeight: true

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: Weather.available ? WeatherIcons.get(Weather.kind) : "cloud_off"
                            fill: 1
                            font.pixelSize: 52
                            color: Appearance.colors.tertiary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: Weather.available ? `${Weather.temp}°` : "--"
                                font.family: Appearance.font.family.mono
                                font.pixelSize: Appearance.font.size.extraLarge
                                font.weight: Font.Medium
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Weather.available ? Weather.description : "Tidak ada data"
                                color: Appearance.colors.textDim
                                font.pixelSize: Appearance.font.size.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Weather.location
                                color: Appearance.colors.textDim
                                font.pixelSize: Appearance.font.size.small
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Appearance.spacing.normal

                // Jam
                Card {
                    Layout.preferredWidth: 150
                    Layout.fillHeight: true

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Appearance.spacing.normal
                        spacing: -6

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(Time.date, "hh")
                            color: Appearance.colors.primary
                            font.family: Appearance.font.family.mono
                            font.pixelSize: 64
                            font.bold: true
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(Time.date, "mm")
                            color: Appearance.colors.secondary
                            font.family: Appearance.font.family.mono
                            font.pixelSize: 64
                            font.bold: true
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Appearance.spacing.small
                        text: Time.date.toLocaleString(Qt.locale(), "dddd, d MMM")
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Calendar {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        NowPlaying {
            Layout.preferredWidth: 220
            Layout.fillHeight: true
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledSlider {
            Layout.fillWidth: true
            icon: Audio.muted ? "volume_off" : "volume_up"
            value: Audio.muted ? 0 : Audio.volume
            onMoved: v => Audio.setVolume(v)
        }

        StyledSlider {
            Layout.fillWidth: true
            visible: Brightness.available
            icon: "light_mode"
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
            onClicked: Notifs.dnd = !Notifs.dnd
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
            icon: "settings"
            padding: Appearance.padding.normal - 2
            onClicked: DrawerState.open("settings")
        }
    }
}
