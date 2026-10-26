import QtQuick
import qs.components
import qs.services
import qs.utils

// Visualizer cava dot-matrix di dasar layar: hanya titik yang menyala digambar, jadi wallpaper tetap
// bersih. Diam (dan cava berhenti) saat tidak ada lagu.
Item {
    id: root

    opacity: Media.playing ? 0.8 : 0

    Behavior on opacity {
        Anim {
            duration: Appearance.anim.durations.large
        }
    }

    DotColumns {
        anchors.fill: parent
        columns: Cava.bars
        rows: 14
        showOff: false
        values: Cava.values
    }
}
