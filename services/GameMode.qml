pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// Mode game: matikan animasi, blur, bayangan, dan gap Hyprland, plus sembunyikan popup notifikasi.
// Mematikan mode = hyprctl reload, jadi nilai dari config Hyprland kembali.
Singleton {
    id: root

    property bool enabled: false

    function toggle(): void {
        enabled = !enabled;
        if (enabled)
            Quickshell.execDetached(["hyprctl", "--batch", ["keyword animations:enabled 0", "keyword decoration:shadow:enabled 0", "keyword decoration:blur:enabled 0", "keyword general:gaps_in 0", "keyword general:gaps_out 0", "keyword general:border_size 1", "keyword decoration:rounding 0"].join(";")]);
        else
            Quickshell.execDetached(["hyprctl", "reload"]);
        Toaster.show("sports_esports", enabled ? "Mode game aktif" : "Mode game mati", enabled ? "Animasi dan efek Hyprland dimatikan" : "Config Hyprland dimuat ulang", "");
    }

    IpcHandler {
        target: "gamemode"

        function toggle(): void {
            root.toggle();
        }

        function isEnabled(): bool {
            return root.enabled;
        }
    }
}
