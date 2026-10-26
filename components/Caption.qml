import QtQuick
import qs.utils

// Label judul kecil ala retro: mono, huruf besar, sedikit renggang, warna aksen.
StyledText {
    color: Appearance.colors.primary
    font.family: Appearance.font.family.title
    font.pixelSize: Appearance.font.size.small
    font.weight: Font.Medium
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1
}
