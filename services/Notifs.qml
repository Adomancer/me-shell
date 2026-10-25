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
    // Waktu masuk per id notifikasi (ms), untuk label "5 mnt"
    property var times: ({})
    // Berdetak tiap menit supaya label waktu ikut diperbarui
    property real now: Date.now()

    function ago(notif): string {
        const t = times[notif?.id];
        if (!t)
            return "";
        const m = Math.floor((now - t) / 60000);
        return m < 1 ? "baru saja" : m < 60 ? `${m} mnt` : `${Math.floor(m / 60)} jam`;
    }

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
            root.times[notif.id] = Date.now();
            root.now = Date.now();
            notif.closed.connect(() => root.dismissPopup(notif));
            if (!root.dnd || notif.urgency === NotificationUrgency.Critical)
                root.popups = [notif, ...root.popups].slice(0, 5);
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.list.length > 0
        onTriggered: root.now = Date.now()
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
