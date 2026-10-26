import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Baterai (persen, sisa waktu) dan pilihan power profile.
ColumnLayout {
    id: root

    readonly property int pageWidth: 300

    spacing: Appearance.spacing.normal

    RowLayout {
        Layout.fillWidth: true
        visible: Battery.available
        spacing: Appearance.spacing.large

        CircularProgress {
            size: 72
            thickness: 7
            value: Battery.percentage
            label: Battery.charging ? "isi" : ""
            color: !Battery.charging && Battery.percentage < 0.15 ? Appearance.colors.error : Appearance.colors.primary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: Battery.charging ? "Mengisi daya" : "Memakai baterai"
                font.pixelSize: Appearance.font.size.larger
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                text: Battery.timeLeftText ? (Battery.charging ? `Penuh dalam ${Battery.timeLeftText}` : `Sisa ${Battery.timeLeftText}`) : "Menghitung sisa waktu..."
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                elide: Text.ElideRight
            }
        }
    }

    ProfilePicker {
        Layout.fillWidth: true
    }
}
