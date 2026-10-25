pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Notification server. Jangan jalankan bersama swaync/mako/dunst.
Singleton {
    id: root

    property bool dnd: false
    // Notifikasi yang sedang tampil sebagai popup (terbaru di depan)
    property var popups: []
    readonly property var list: server.trackedNotifications.values

    function dismissPopup(notif): void {
        popups = popups.filter(p => p !== notif);
    }

    function clearAll(): void {
        for (const n of [...list])
            n.dismiss();
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true;
            notif.closed.connect(() => root.dismissPopup(notif));
            if (!root.dnd || notif.urgency === NotificationUrgency.Critical)
                root.popups = [notif, ...root.popups].slice(0, 5);
        }
    }

    IpcHandler {
        target: "notifs"

        function dnd(): void {
            root.dnd = !root.dnd;
        }

        function clear(): void {
            root.clearAll();
        }
    }
}
