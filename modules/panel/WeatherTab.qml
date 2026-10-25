import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherIcons.js" as WeatherIcons

// Tab Cuaca: kondisi sekarang, tile detail, dan prakiraan beberapa hari.
ColumnLayout {
    id: root

    // Suhu terendah/tertinggi dari semua hari, untuk skala bar rentang
    readonly property real lo: Math.min(...Weather.forecast.map(d => d.min), 99)
    readonly property real hi: Math.max(...Weather.forecast.map(d => d.max), -99)

    function dayName(date: string, index: int): string {
        if (index === 0)
            return "Hari ini";
        const [y, m, d] = date.split("-").map(Number);
        return new Date(y, m - 1, d).toLocaleDateString(Qt.locale(), "dddd");
    }

    component Tile: StyledRect {
        id: tile

        property string icon
        property string label
        property string value

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Appearance.radius.small + 2
        color: Appearance.colors.surfaceContainerHigh

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: tile.icon
                color: Appearance.colors.tertiary
                font.pixelSize: 26
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: tile.label
                    color: Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: tile.value
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.larger
                    font.weight: Font.Medium
                }
            }
        }
    }

    spacing: Appearance.spacing.normal

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.normal

        Card {
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            title: "Sekarang"
            icon: "location_on"
            note: Weather.location

            RowLayout {
                Layout.topMargin: Appearance.spacing.normal
                spacing: Appearance.spacing.large

                MaterialIcon {
                    text: Weather.available ? WeatherIcons.get(Weather.kind) : "cloud_off"
                    fill: 1
                    font.pixelSize: 104
                    color: Appearance.colors.tertiary
                }

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        text: Weather.available ? `${Weather.temp}°` : "--"
                        font.family: Appearance.font.family.mono
                        font.pixelSize: 64
                        font.weight: Font.Medium
                    }

                    StyledText {
                        text: Weather.available ? Weather.description : "Tidak ada data"
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.larger
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: Appearance.spacing.normal
            rowSpacing: Appearance.spacing.normal

            Tile {
                icon: "thermostat"
                label: "Terasa"
                value: `${Weather.feelsLike}°C`
            }
            Tile {
                icon: "humidity_percentage"
                label: "Kelembapan"
                value: `${Weather.humidity}%`
            }
            Tile {
                icon: "air"
                label: "Angin"
                value: `${Weather.wind} km/j ${Weather.windDir}`
            }
            Tile {
                icon: "sunny"
                label: "Indeks UV"
                value: Weather.uv
            }
            Tile {
                icon: "wb_twilight"
                label: "Terbit"
                value: Weather.sunrise
            }
            Tile {
                icon: "nights_stay"
                label: "Terbenam"
                value: Weather.sunset
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        Repeater {
            model: Weather.forecast

            Card {
                id: day

                required property var modelData
                required property int index

                Layout.fillWidth: true

                RowLayout {
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: WeatherIcons.get(day.modelData.kind)
                        fill: 1
                        font.pixelSize: 36
                        color: Appearance.colors.tertiary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        StyledText {
                            text: root.dayName(day.modelData.date, day.index)
                            font.weight: Font.Medium
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: `${day.modelData.min}°`
                                color: Appearance.colors.textDim
                                font.family: Appearance.font.family.mono
                                font.pixelSize: Appearance.font.size.small
                            }

                            // Bar rentang suhu hari itu relatif terhadap semua hari
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 6

                                StyledRect {
                                    anchors.fill: parent
                                    radius: 3
                                    color: Appearance.colors.surfaceContainerHighest
                                }

                                Rectangle {
                                    readonly property real span: Math.max(1, root.hi - root.lo)

                                    x: parent.width * (day.modelData.min - root.lo) / span
                                    width: Math.max(6, parent.width * (day.modelData.max - day.modelData.min) / span)
                                    height: parent.height
                                    radius: 3
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal

                                        GradientStop {
                                            position: 0
                                            color: Appearance.colors.tertiary
                                        }
                                        GradientStop {
                                            position: 1
                                            color: Appearance.colors.primary
                                        }
                                    }
                                }
                            }

                            StyledText {
                                text: `${day.modelData.max}°`
                                font.family: Appearance.font.family.mono
                                font.pixelSize: Appearance.font.size.small
                            }
                        }
                    }
                }
            }
        }
    }
}
