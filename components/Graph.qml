import QtQuick
import qs.utils

// Grafik garis bertangga ala layar fosfor. values dinormalkan terhadap maxValue.
Canvas {
    id: root

    property var values: []
    property real maxValue: 1
    property color color: Appearance.colors.primary

    implicitHeight: 92

    onValuesChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        ctx.strokeStyle = Appearance.colors.outline;
        ctx.lineWidth = 1;
        for (let y = 23; y < height; y += 23) {
            ctx.beginPath();
            ctx.moveTo(0, y + 0.5);
            ctx.lineTo(width, y + 0.5);
            ctx.stroke();
        }

        if (values.length < 2)
            return;
        const step = width / (values.length - 1);
        const yOf = v => height - 4 - Math.max(0, Math.min(1, v / (maxValue || 1))) * (height - 8);
        ctx.beginPath();
        let py = yOf(values[0]);
        ctx.moveTo(0, py);
        for (let i = 1; i < values.length; i++) {
            const y = yOf(values[i]);
            ctx.lineTo(i * step, py);
            ctx.lineTo(i * step, y);
            py = y;
        }
        ctx.strokeStyle = root.color;
        ctx.lineWidth = 2;
        ctx.stroke();

        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.12);
        ctx.fill();
    }
}
