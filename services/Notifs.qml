pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs.services

// Notification server. Jangan jalankan bersama swaync/mako/dunst.
Singleton {
    id: root

    property bool dnd: false
    // Notifikasi yang sedang tampil sebagai popup (terbaru di depan)
    property var popups: []
    readonly property var list: server.trackedNotifications.values
    // { aplikasi: [notifikasi terbaru dulu] }, urutan kunci = aplikasi dengan notifikasi terbaru dulu
    readonly property var groups: {
        const g = {};
        for (const n of [...list].reverse()) {
            const k = n.appName || "Lainnya";
            (g[k] = g[k] || []).push(n);
        }
        return g;
    }
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

    function toggleDnd(): void {
        dnd = !dnd;
        Toaster.show(dnd ? "notifications_off" : "notifications_active", dnd ? "Jangan ganggu aktif" : "Jangan ganggu mati", dnd ? "Popup notifikasi disembunyikan" : "", "");
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
            notif.closed.connect(() => {
                root.dismissPopup(notif);
                delete root.times[notif.id];
            });
            if ((!root.dnd && !GameMode.enabled) || notif.urgency === NotificationUrgency.Critical)
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
            root.toggleDnd();
        }

        function clear(): void {
            root.clearAll();
        }
    }
}
