import QtQuick
import qs.utils

// Angka besar dot-matrix (font Doto, titik bulat). Untuk jam dan persen utama.
StyledText {
    // Tebal titik (100-900); ukuran kecil butuh lebih tebal supaya terbaca
    property int weight: 700

    font.family: Appearance.font.family.display
    font.pixelSize: Appearance.font.size.huge
    // Ikut diset supaya fontconfig memilih instance yang tepat kalau sumbu variabel diabaikan
    font.weight: weight
    font.variableAxes: ({
            ROND: 100,
            wght: weight
        })
}
