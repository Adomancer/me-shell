import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherArt.js" as WeatherArt
import "../../utils/PixelIcons.js" as Icons

GridLayout {
    id: root

    component Key: StyledText {
        Layout.preferredWidth: 80
        color: Appearance.colors.primary
        font.pixelSize: Appearance.font.size.small
        font.bold: true
    }

    component Value: StyledText {
        Layout.fillWidth: true
    }

    function dayName(date: string, index: int): string {
        if (index === 0)
            return "HARI INI";
        const [y, m, d] = date.split("-").map(Number);
        return new Date(y, m - 1, d).toLocaleDateString(Qt.locale(), "dddd").toUpperCase();
    }

    columns: 2
    columnSpacing: Appearance.spacing.normal
    rowSpacing: Appearance.spacing.normal

    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "sekarang"
        note: Weather.location

        RowLayout {
            visible: Weather.available
            spacing: Appearance.spacing.huge

            StyledText {
                text: WeatherArt.get(Weather.kind)
                textFormat: Text.PlainText
                color: Appearance.colors.primary
                font.pixelSize: Appearance.font.size.large
                lineHeight: 0.9
            }

            ColumnLayout {
                spacing: 2

                StyledText {
                    text: `${Weather.temp}°`
                    font.pixelSize: 56
                    font.bold: true
                }

                StyledText {
                    text: Weather.description.toUpperCase()
                    font.bold: true
                }
            }
        }

        StyledText {
            visible: !Weather.available
            text: "-- TIDAK ADA DATA (cek koneksi) --"
            color: Appearance.colors.textDim
        }
    }

    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "detail"

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Appearance.spacing.normal
            rowSpacing: 4

            Key {
                text: "TERASA"
            }
            Value {
                text: `${Weather.feelsLike}°C`
            }
            Key {
                text: "LEMBAP"
            }
            Value {
                text: `${Weather.humidity}%`
            }
            Key {
                text: "ANGIN"
            }
            Value {
                text: `${Weather.wind} km/j · ${Weather.windDir}`
            }
            Key {
                text: "UV"
            }
            Value {
                text: Weather.uv
            }
            Key {
                text: "TERBIT"
            }
            Value {
                text: Weather.sunrise
            }
            Key {
                text: "TERBENAM"
            }
            Value {
                text: Weather.sunset
            }
        }
    }

    RowLayout {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        Repeater {
            model: Weather.forecast

            Card {
                id: day

                required property var modelData
                required property int index

                Layout.fillWidth: true

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.dayName(day.modelData.date, day.index)
                    font.bold: true
                }

                PixelIcon {
                    Layout.alignment: Qt.AlignHCenter
                    rows: Icons.weather[day.modelData.kind] ?? Icons.weather.cloud
                    pixel: 3
                    color: Appearance.colors.primary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: `${day.modelData.max}° / ${day.modelData.min}°`
                    font.pixelSize: Appearance.font.size.small
                }
            }
        }
    }
}
