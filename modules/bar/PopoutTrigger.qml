import Quickshell
import QtQuick
import qs.services
import qs.utils

// Area di bar yang memunculkan popout saat di-hover. Taruh sesudah StateLayer item itu (HoverHandler
// butuh item yang menerima hover di bawahnya), lalu panggil pin() dari onClicked StateLayer.
Item {
    id: root

    required property string popout

    function centerX(): real {
        return root.mapToItem(null, root.width / 2, 0).x;
    }

    function screenName(): string {
        return QsWindow.window?.screen?.name ?? "";
    }

    // Klik = sematkan popout (bisa diketik, klik di luar menutup); klik lagi = tutup
    function pin(): void {
        DrawerState.pinPopout(popout, centerX(), screenName());
    }

    anchors.fill: parent

    HoverHandler {
        enabled: Config.barPopouts
        onHoveredChanged: {
            if (hovered)
                DrawerState.showPopout(root.popout, root.centerX(), root.screenName());
            else
                DrawerState.leavePopout(root.popout);
        }
    }
}
