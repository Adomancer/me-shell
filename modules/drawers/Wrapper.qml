import QtQuick
import qs.components
import qs.utils

// Wadah drawer yang menempel di tepi. Ukurannya ke dalam layar 0 saat tertutup (otomatis keluar dari
// mask input), lalu membesar dengan pegas saat dibuka. Isinya ditambatkan ke sisi jauh, jadi ikut
// meluncur keluar dari tepi.
Item {
    id: root

    property bool shown: false
    // "top", "bottom", "left", "right"
    property string edge: "top"
    // Item isi tunggal; ukurannya dari implicitWidth/implicitHeight
    default property Item content

    readonly property bool vertical: edge === "left" || edge === "right"
    // Kursor di atas drawer; dipakai drawer yang dibuka dengan hover
    readonly property bool hovered: hover.hovered
    property real progress: shown ? 1 : 0
    property real contentW: content?.implicitWidth ?? 0
    property real contentH: content?.implicitHeight ?? 0

    implicitWidth: vertical ? contentW * progress : contentW
    implicitHeight: vertical ? contentH : contentH * progress
    visible: progress > 0
    clip: true

    onContentChanged: {
        if (!content)
            return;
        content.parent = root;
        content.width = Qt.binding(() => root.contentW);
        content.height = Qt.binding(() => root.contentH);
        content.x = Qt.binding(() => root.edge === "right" ? 0 : root.edge === "left" ? root.width - root.contentW : 0);
        content.y = Qt.binding(() => root.edge === "top" ? root.height - root.contentH : 0);
        content.opacity = Qt.binding(() => Math.min(1, root.progress * 2));
    }

    // Menerima hover di area kosong supaya HoverHandler selalu jalan
    MouseArea {
        z: -1
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    HoverHandler {
        id: hover
    }

    Behavior on progress {
        Anim {
            duration: root.shown ? Appearance.anim.durations.expressiveDefault : Appearance.anim.durations.normal
            easing.bezierCurve: root.shown ? Appearance.anim.curves.expressiveDefault : Appearance.anim.curves.emphasizedAccel
        }
    }

    // Ukuran isi berubah (pindah tab dsb.): panel ikut mengembang/menyusut halus
    Behavior on contentW {
        enabled: root.shown

        Anim {
            duration: Appearance.anim.durations.expressiveDefault
            easing.bezierCurve: Appearance.anim.curves.expressiveDefault
        }
    }
    Behavior on contentH {
        enabled: root.shown

        Anim {
            duration: Appearance.anim.durations.expressiveDefault
            easing.bezierCurve: Appearance.anim.curves.expressiveDefault
        }
    }
}
