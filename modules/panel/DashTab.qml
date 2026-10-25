import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherArt.js" as WeatherArt

// Tata letak ala tab Dashboard Caelestia: cuaca + user di atas, jam + kalender + meter di bawah,
// kaset di kanan, lalu kontrol cepat.
ColumnLayout {
    id: root

    readonly property var player: Media.active

    function toggleText(name: string, on: bool): string {
        return `${on ? "[x]" : "[ ]"} ${name}`;
    }

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

                Card {
                    Layout.preferredWidth: 280
                    Layout.fillHeight: true
                    title: "weather"
                    note: Weather.location

                    RowLayout {
                        visible: Weather.available
                        spacing: Appearance.spacing.large

                        StyledText {
                            text: WeatherArt.get(Weather.kind)
                            textFormat: Text.PlainText
                            color: Appearance.colors.primary
                            font.pixelSize: Appearance.font.size.small
                            lineHeight: 0.9
                        }

                        ColumnLayout {
                            spacing: 2

                            StyledText {
                                text: `${Weather.temp}°C`
                                font.pixelSize: 28
                                font.bold: true
                            }

                            StyledText {
                                Layout.maximumWidth: 110
                                text: Weather.description.toUpperCase()
                                color: Appearance.colors.textDim
                                font.pixelSize: Appearance.font.size.small
                                elide: Text.ElideRight
                            }
                        }
                    }

                    StyledText {
                        visible: !Weather.available
                        text: "-- TIDAK ADA DATA --"
                        color: Appearance.colors.textDim
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        spacing: Appearance.spacing.large

                        Avatar {
                            size: 64
                            source: `file://${UserInfo.avatar}`
                            initial: UserInfo.displayName.charAt(0).toUpperCase()
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: UserInfo.displayName.toUpperCase()
                                font.pixelSize: Appearance.font.size.large
                                font.bold: true
                                font.letterSpacing: 2
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: `${UserInfo.wm} · ${UserInfo.distro}`
                                color: Appearance.colors.textDim
                                font.pixelSize: Appearance.font.size.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: `UP ${UserInfo.uptime}`
                                font.pixelSize: Appearance.font.size.small
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Network.ethernet ? "> ETHERNET" : Network.connected ? `> ${Network.ssid} · ${Network.signal}%` : "> OFFLINE"
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

                // Jam bertumpuk
                Card {
                    Layout.preferredWidth: 132
                    Layout.fillHeight: true

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(Time.date, "hh")
                            color: Appearance.colors.primary
                            font.pixelSize: 52
                            font.bold: true
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(Time.date, "mm")
                            color: Appearance.colors.primary
                            font.pixelSize: 52
                            font.bold: true
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(Time.date, "ddd dd").toUpperCase()
                            color: Appearance.colors.textDim
                            font.pixelSize: Appearance.font.size.small
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Calendar {
                        Layout.fillWidth: true
                    }
                }

                Card {
                    Layout.preferredWidth: 112
                    Layout.fillHeight: true
                    title: "sys"

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        VuMeter {
                            label: "CPU"
                            value: SystemStats.cpu
                        }

                        VuMeter {
                            label: "RAM"
                            value: SystemStats.memory
                        }

                        VuMeter {
                            label: "DSK"
                            value: SystemStats.disk
                        }
                    }
                }
            }
        }

        Card {
            Layout.preferredWidth: 196
            Layout.fillHeight: true
            title: "tape"
            note: root.player?.identity ?? ""

            Cassette {
                Layout.fillWidth: true
                label: root.player ? `${root.player.trackTitle} · ${root.player.trackArtist}` : "no tape"
                playing: Media.playing
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small
                text: root.player?.trackTitle || "TIDAK ADA MEDIA"
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                elide: Text.ElideRight
            }

            SegmentSlider {
                Layout.fillWidth: true
                visible: (root.player?.length ?? 0) > 0
                implicitHeight: 6
                segments: 16
                showValue: false
                value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
                onMoved: v => {
                    if (root.player?.canSeek)
                        root.player.position = v * root.player.length;
                }
            }

            Row {
                visible: root.player !== null
                spacing: Appearance.spacing.small

                RetroButton {
                    text: "|<"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }

                RetroButton {
                    text: Media.playing ? "||" : ">"
                    active: true
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }

                RetroButton {
                    text: ">|"
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }
            }
        }
    }

    // Kontrol cepat
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.huge

        SegmentSlider {
            Layout.fillWidth: true
            label: "VOL"
            value: Audio.muted ? 0 : Audio.volume
            onMoved: v => Audio.setVolume(v)
        }

        SegmentSlider {
            Layout.fillWidth: true
            visible: Brightness.available
            label: "LCD"
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }

        Row {
            spacing: Appearance.spacing.small

            RetroButton {
                text: root.toggleText("WIFI", Network.wifiEnabled)
                active: Network.wifiEnabled
                onClicked: Network.setWifi(!Network.wifiEnabled)
            }

            RetroButton {
                enabled: BluetoothService.available
                text: root.toggleText("BT", BluetoothService.enabled)
                active: BluetoothService.enabled
                onClicked: BluetoothService.toggle()
            }

            RetroButton {
                text: root.toggleText("DND", Notifs.dnd)
                active: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            RetroButton {
                text: root.toggleText("MIC", !Audio.micMuted)
                active: !Audio.micMuted
                onClicked: Audio.toggleMic()
            }

            RetroButton {
                text: "[CFG]"
                onClicked: DrawerState.open("settings")
            }
        }
    }
}
