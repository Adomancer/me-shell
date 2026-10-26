pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Toast kecil di pojok kanan bawah untuk kabar dari shell sendiri (mode game, rekaman, screenshot, ...).
// Beda dengan notifikasi: tidak masuk riwayat dan hilang sendiri.
Singleton {
    id: root

    // [{ id, icon, title, body, image, expires }], terbaru di depan
    property var toasts: []
    property int nextId: 1
    // Abaikan kabar saat startup (status awal service ikut "berubah")
    property bool ready: false

    function show(icon: string, title: string, body: string, image: string): void {
        if (!ready)
            return;
        const t = {
            id: nextId++,
            icon,
            title,
            body: body ?? "",
            image: image ?? "",
            expires: Date.now() + 4000
        };
        toasts = [t, ...toasts].slice(0, 4);
    }

    function dismiss(id: int): void {
        toasts = toasts.filter(t => t.id !== id);
    }

    // Tahan semua toast selama kursor di atasnya
    function hold(): void {
        const later = Date.now() + 2500;
        toasts = toasts.map(t => Object.assign({}, t, {
                expires: Math.max(t.expires, later)
            }));
    }

    Timer {
        interval: 500
        repeat: true
        running: root.toasts.length > 0
        onTriggered: {
            const now = Date.now();
            if (root.toasts.some(t => t.expires < now))
                root.toasts = root.toasts.filter(t => t.expires >= now);
        }
    }

    Timer {
        interval: 3000
        running: true
        onTriggered: root.ready = true
    }

    IpcHandler {
        target: "toast"

        // Bukan "show": nama itu bentrok dengan subcommand `qs ipc show`
        function post(title: string, body: string): void {
            root.show("info", title, body, "");
        }
    }
}
