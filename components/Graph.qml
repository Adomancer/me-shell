import QtQuick
import qs.utils

// Grafik kurva halus dengan isi gradasi. values dinormalkan terhadap maxValue.
Canvas {
    id: root

    property var values: []
    property real maxValue: 1
    property color color: Appearance.colors.primary
    property bool grid: true

    implicitHeight: 92

    onValuesChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        if (grid) {
            ctx.strokeStyle = Appearance.alpha(Appearance.colors.outlineVariant, 0.5);
            ctx.lineWidth = 1;
            ctx.setLineDash([2, 4]);
            for (let i = 1; i < 4; i++) {
                const y = Math.round(height * i / 4) + 0.5;
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }
            ctx.setLineDash([]);
        }

        if (values.length < 2)
            return;
        const step = width / (values.length - 1);
        const pts = values.map((v, i) => ({
                    x: i * step,
                    y: height - 3 - Math.max(0, Math.min(1, v / (maxValue || 1))) * (height - 6)
                }));

        // Kurva melewati titik tengah antar sampel supaya mulus
        ctx.beginPath();
        ctx.moveTo(pts[0].x, pts[0].y);
        for (let i = 1; i < pts.length - 1; i++) {
            const mx = (pts[i].x + pts[i + 1].x) / 2;
            const my = (pts[i].y + pts[i + 1].y) / 2;
            ctx.quadraticCurveTo(pts[i].x, pts[i].y, mx, my);
        }
        const last = pts[pts.length - 1];
        ctx.lineTo(last.x, last.y);
        ctx.strokeStyle = root.color;
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.stroke();

        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        const g = ctx.createLinearGradient(0, 0, 0, height);
        g.addColorStop(0, Appearance.alpha(root.color, 0.35));
        g.addColorStop(1, Appearance.alpha(root.color, 0));
        ctx.fillStyle = g;
        ctx.fill();
    }
}
