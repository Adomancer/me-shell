import QtQuick
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherIcons.js" as WeatherIcons

Tile {
    id: root

    readonly property var today: Weather.forecast[0] ?? null

    Caption {
        anchors.left: parent.left
        anchors.right: icon.left
        anchors.top: parent.top
        text: Weather.location || "Cuaca"
        elide: Text.ElideRight
    }

    MaterialIcon {
        id: icon

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -4
        text: Weather.available ? WeatherIcons.get(Weather.kind) : "cloud_off"
        fill: 1
        font.pixelSize: 32
        color: Appearance.colors.primary
    }

    DisplayText {
        anchors.left: parent.left
        anchors.leftMargin: -2
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -4
        text: Weather.available ? `${Weather.temp}°` : "--"
        weight: 800
        font.pixelSize: Math.round(Math.min(parent.height * 0.42, parent.width * 0.3))
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 2

        StyledText {
            width: parent.width
            text: Weather.available ? Weather.description : "Tidak ada data"
            color: Appearance.colors.text
            elide: Text.ElideRight
        }

        Caption {
            width: parent.width
            visible: Weather.available
            text: root.today ? `↑ ${root.today.max}°   ↓ ${root.today.min}°   ${Weather.humidity}%` : `Terasa ${Weather.feelsLike}°`
            elide: Text.ElideRight
        }
    }
}
