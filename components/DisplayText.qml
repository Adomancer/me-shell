import QtQuick
import qs.utils

// Angka besar dot-matrix (font Doto, titik bulat). Untuk jam dan persen utama.
StyledText {
    font.family: Appearance.font.family.display
    font.pixelSize: Appearance.font.size.huge
    font.variableAxes: ({
            ROND: 100,
            wght: 700
        })
}
