import QtQuick
import qs.components
import qs.utils

// Pilihan bergilir dengan tombol panah. SettingStepper memakai ini untuk angka (wrap: false).
// Saat nilai berganti, teks lama bergeser keluar dan yang baru masuk dari arah tombol.
StyledRect {
    id: root

    property var options: []
    property var value
    property int labelWidth: 140
    // false = berhenti di ujung daftar, tidak berputar
    property bool wrap: true
    // Ubah tampilan nilai, misalnya menambah satuan
    property var format: v => String(v)
    property int direction: 1

    signal picked(var value)

    function step(delta: int): void {
        const i = Math.max(0, options.indexOf(value));
        const n = options.length;
        const next = wrap ? (i + delta + n) % n : Math.max(0, Math.min(n - 1, i + delta));
        if (options[next] !== value) {
            direction = delta;
            picked(options[next]);
        }
    }

    implicitWidth: row.implicitWidth + 4
    implicitHeight: 40
    radius: Appearance.radius.small
    color: Appearance.colors.surfaceContainerHighest

    onValueChanged: swap.restart()

    Row {
        id: row

        anchors.centerIn: parent

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "chevron_left"
            onClicked: root.step(-1)
        }

        Item {
            width: root.labelWidth
            height: root.height
            clip: true

            StyledText {
                id: label

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.format(root.value)
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "chevron_right"
            onClicked: root.step(1)
        }
    }

    SequentialAnimation {
        id: swap

        PropertyAction {
            target: label
            property: "x"
            value: root.direction * 24
        }
        PropertyAction {
            target: label
            property: "opacity"
            value: 0
        }
        ParallelAnimation {
            Anim {
                target: label
                property: "x"
                to: 0
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
            Anim {
                target: label
                property: "opacity"
                to: 1
                duration: Appearance.anim.durations.small
            }
        }
    }
}
