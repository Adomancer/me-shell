import QtQuick
import qs.utils

// Visualizer dot-matrix: tiap kolom = tumpukan titik, yang menyala sesuai level (0..1) dari bawah.
// Level dianimasikan, jadi titik naik-turun halus.
Item {
    id: root

    // Nilai 0..1 per kolom
    property var values: []
    property int columns: 32
    property int rows: 10
    property color onColor: Appearance.colors.primary
    // Titik mati ikut digambar redup (false = hanya titik menyala)
    property bool showOff: true
    property color offColor: Appearance.colors.hairline
    readonly property real cellW: width / columns
    readonly property real cellH: height / rows
    readonly property real dot: Math.max(2, Math.min(cellW, cellH) * 0.62)

    Repeater {
        model: root.columns

        Item {
            id: column

            required property int index
            property real level: Math.max(0, Math.min(1, root.values[index] ?? 0))
            readonly property int lit: Math.round(level * root.rows)

            x: index * root.cellW
            width: root.cellW
            height: root.height

            Behavior on level {
                Anim {
                    duration: 140
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }

            Repeater {
                model: root.rows

                Rectangle {
                    required property int index
                    readonly property bool on: index < column.lit

                    x: (column.width - width) / 2
                    y: root.height - (index + 1) * root.cellH + (root.cellH - height) / 2
                    width: root.dot
                    height: root.dot
                    radius: width / 2
                    visible: on || root.showOff
                    color: on ? root.onColor : root.offColor
                }
            }
        }
    }
}
