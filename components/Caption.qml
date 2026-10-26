import QtQuick
import qs.utils

// Label kecil ala Nothing/TE: mono, huruf besar, renggang, abu-abu (aksen dihemat).
StyledText {
    color: Appearance.colors.textDim
    font.family: Appearance.font.family.title
    font.pixelSize: Appearance.font.size.small
    font.weight: Font.Medium
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1.5
}
