pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.utils

// Wallpaper aktif disimpan di ~/.local/state/me-shell/wallpaper.json.
// Setiap ganti wallpaper, warna digenerate ulang lewat matugen.
Singleton {
    id: root

    readonly property string current: adapter.path

    function set(path: string): void {
        const p = Paths.expand(path);
        adapter.path = p;
        file.writeAdapter();
        Quickshell.execDetached(["sh", `${Paths.shell}/scripts/gen-colors.sh`, p, Config.colorMode]);
        Toaster.show("wallpaper", "Wallpaper diganti", p.split("/").pop(), p);
    }

    FileView {
        id: file

        path: `${Paths.state}/wallpaper.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property string path: ""
        }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            root.set(path);
        }

        function get(): string {
            return root.current;
        }
    }
}
