import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherArt.js" as WeatherArt

Card {
    title: "weather"
    note: Weather.location

    RowLayout {
        Layout.fillWidth: true
        visible: Weather.available
        spacing: Appearance.spacing.huge

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
                font.pixelSize: 32
                font.bold: true
            }

            StyledText {
                Layout.fillWidth: true
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
