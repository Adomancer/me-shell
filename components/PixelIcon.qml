import QtQuick
import qs.utils

// Ikon pixel art dari daftar baris string ("#" = pixel nyala), lihat utils/PixelIcons.js.
Canvas {
    id: root

    property var rows: []
    property color color: Appearance.colors.text
    // Ukuran satu pixel dalam px
    property int pixel: 2
    readonly property int cols: rows.reduce((m, r) => Math.max(m, r.length), 0)

    implicitWidth: cols * pixel
    implicitHeight: rows.length * pixel

    onRowsChanged: requestPaint()
    onColorChanged: requestPaint()
    onPixelChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = root.color;
        for (let y = 0; y < rows.length; y++)
            for (let x = 0; x < rows[y].length; x++)
                if (rows[y][x] === "#")
                    ctx.fillRect(x * pixel, y * pixel, pixel, pixel);
    }
}
