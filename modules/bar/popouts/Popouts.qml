import QtQuick
import qs.components
import qs.services
import qs.utils

// Isi drawer popout bar. Halaman berganti dengan memudar silang; ukuran drawer ikut halaman aktif
// (Wrapper yang menganimasikan), jadi popout melar/menyusut saat kursor pindah ikon.
Item {
    id: root

    // "tray:<judul>" membawa teks tooltip
    readonly property string current: DrawerState.popout.split(":")[0]
    // Halaman terakhir tetap dipakai selama animasi tutup supaya isinya tidak hilang duluan
    property string shownName: ""
    property string trayText: ""
    readonly property Loader page: pages[shownName] ?? null
    readonly property var pages: ({
            network: network,
            bluetooth: bluetooth,
            audio: audio,
            battery: battery,
            window: windowPage,
            media: media,
            tray: tray
        })
    readonly property int pad: Appearance.padding.large

    implicitWidth: (page?.width ?? 0) + pad * 2
    implicitHeight: (page?.height ?? 0) + pad * 2

    onCurrentChanged: {
        if (current === "")
            return;
        shownName = current;
        if (current === "tray")
            trayText = DrawerState.popout.slice(5);
    }

    // Menerima hover di area kosong supaya HoverHandler di bawah selalu jalan
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    HoverHandler {
        onHoveredChanged: hovered ? DrawerState.holdPopout() : DrawerState.leavePopout(DrawerState.popout)
    }

    // Halaman memberi lebarnya lewat pageWidth (implicitWidth layout dihitung ulang oleh layout itu sendiri)
    component Page: Loader {
        required property string name
        readonly property bool isCurrent: root.shownName === name

        x: Math.round((root.width - width) / 2)
        y: root.pad
        active: isCurrent || opacity > 0
        opacity: isCurrent ? 1 : 0
        width: item?.pageWidth ?? item?.implicitWidth ?? 0
        height: item?.implicitHeight ?? 0

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.small
            }
        }
    }

    Page {
        id: network

        name: "network"
        sourceComponent: NetworkPopout {}
    }

    Page {
        id: bluetooth

        name: "bluetooth"
        sourceComponent: BluetoothPopout {}
    }

    Page {
        id: audio

        name: "audio"
        sourceComponent: AudioPopout {}
    }

    Page {
        id: battery

        name: "battery"
        sourceComponent: BatteryPopout {}
    }

    Page {
        id: windowPage

        name: "window"
        sourceComponent: WindowPopout {}
    }

    Page {
        id: media

        name: "media"
        sourceComponent: MediaPopout {}
    }

    Page {
        id: tray

        name: "tray"
        sourceComponent: StyledText {
            text: root.trayText
            font.weight: Font.Medium
        }
    }
}
