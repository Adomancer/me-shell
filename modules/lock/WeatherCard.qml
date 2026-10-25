import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherIcons.js" as WeatherIcons

Card {
    title: "Cuaca"
    icon: "partly_cloudy_day"
    note: Weather.location
    color: Appearance.alpha(Appearance.colors.surfaceContainer, 0.85)

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.large

        MaterialIcon {
            text: Weather.available ? WeatherIcons.get(Weather.kind) : "cloud_off"
            fill: 1
            font.pixelSize: 56
            color: Appearance.colors.tertiary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Weather.available ? `${Weather.temp}°C` : "--"
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.extraLarge
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.available ? Weather.description : "Tidak ada data"
                color: Appearance.colors.textDim
                elide: Text.ElideRight
            }
        }
    }
}
