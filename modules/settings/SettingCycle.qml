import QtQuick
import qs.components
import qs.utils

// Pilihan bergilir: < NILAI >. SettingStepper memakai ini untuk angka (wrap: false).
StyledRect {
    id: root

    component Arrow: StyledRect {
        id: arrow

        property string glyph

        signal hit

        width: 32
        height: 28
        radius: 0
        color: mouse.containsMouse ? Appearance.colors.surfaceHigh : "transparent"

        StyledText {
            anchors.centerIn: parent
            text: arrow.glyph
            color: Appearance.colors.primary
            font.bold: true
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: arrow.hit()
        }
    }

    property var options: []
    property var value
    property int labelWidth: 140
    // false = berhenti di ujung daftar, tidak berputar
    property bool wrap: true
    // Ubah tampilan nilai, misalnya menambah satuan
    property var format: v => String(v).toUpperCase()

    signal picked(var value)

    function step(delta: int): void {
        const i = Math.max(0, options.indexOf(value));
        const n = options.length;
        const next = wrap ? (i + delta + n) % n : Math.max(0, Math.min(n - 1, i + delta));
        if (options[next] !== value)
            picked(options[next]);
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    border.width: Appearance.border.thin
    border.color: Appearance.colors.outline

    Row {
        id: row

        Arrow {
            glyph: "<"
            onHit: root.step(-1)
        }

        StyledText {
            width: root.labelWidth
            height: 28
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.format(root.value)
            font.bold: true
            elide: Text.ElideRight
        }

        Arrow {
            glyph: ">"
            onHit: root.step(1)
        }
    }
}
