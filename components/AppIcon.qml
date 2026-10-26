import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.utils

// Ikon aplikasi dari tema ikon. Abu-abu kalau setting "Ikon monokrom" aktif, berwarna saat `lit`
// (dipilih, di-hover, atau aktif), dengan transisi halus.
Item {
    id: root

    // Nama ikon dari desktop entry
    property string icon
    // Bisa diisi langsung kalau ikonnya sudah berupa path/URL (misalnya ikon tray)
    // iconPath(nama, fallback) dengan nama kosong menghasilkan path rusak, jadi selalu beri nama
    property string source: Quickshell.iconPath(icon || "application-x-executable", "application-x-executable")
    property bool lit: false
    property int size: 32

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: img

        anchors.fill: parent
        visible: !Config.monoIcons
        implicitSize: root.size
        source: root.source
        asynchronous: true
    }

    MultiEffect {
        anchors.fill: img
        visible: Config.monoIcons
        source: img
        saturation: root.lit ? 0 : -1
        brightness: root.lit ? 0 : -0.08

        Behavior on saturation {
            Anim {}
        }
        Behavior on brightness {
            Anim {}
        }
    }
}
