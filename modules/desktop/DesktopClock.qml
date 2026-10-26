import QtQuick
import QtQuick.Effects
import qs.components
import qs.services
import qs.utils
import "../../utils/WeatherIcons.js" as WeatherIcons

// Jam dot-matrix besar di atas wallpaper (titik dua aksen), tanggal sebagai label mono, lalu cuaca.
// Bayangan lembut supaya tetap terbaca di wallpaper terang.
Item {
    id: root

    // Text.AlignLeft, Text.AlignRight, atau Text.AlignHCenter
    property int align: Text.AlignLeft

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 0.8
        shadowColor: Appearance.alpha(Appearance.colors.shadow, 0.6)
        shadowVerticalOffset: 2
    }

    Column {
        id: col

        anchors.fill: parent
        spacing: 0

        Row {
            anchors.left: root.align === Text.AlignLeft ? parent.left : undefined
            anchors.right: root.align === Text.AlignRight ? parent.right : undefined
            anchors.horizontalCenter: root.align === Text.AlignHCenter ? parent.horizontalCenter : undefined
            spacing: 0

            DisplayText {
                text: Qt.formatDateTime(Time.date, "hh")
                font.pixelSize: Appearance.font.size.giant
            }

            DisplayText {
                text: ":"
                color: Appearance.colors.primary
                font.pixelSize: Appearance.font.size.giant
            }

            DisplayText {
                text: Qt.formatDateTime(Time.date, "mm")
                font.pixelSize: Appearance.font.size.giant
            }
        }

        Caption {
            width: parent.width
            horizontalAlignment: root.align
            text: Time.date.toLocaleString(Qt.locale(), "dddd, d MMMM")
            color: Appearance.colors.text
            font.pixelSize: Appearance.font.size.large
        }

        Row {
            anchors.left: root.align === Text.AlignLeft ? parent.left : undefined
            anchors.right: root.align === Text.AlignRight ? parent.right : undefined
            anchors.horizontalCenter: root.align === Text.AlignHCenter ? parent.horizontalCenter : undefined
            topPadding: Appearance.spacing.small
            spacing: Appearance.spacing.small
            visible: Weather.available

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: WeatherIcons.get(Weather.kind)
                font.pixelSize: Appearance.font.size.extraLarge
                color: Appearance.colors.text
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Weather.temp}°  ${Weather.description}`
                color: Appearance.colors.textDim
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.larger
            }
        }
    }
}
