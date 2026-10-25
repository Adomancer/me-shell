pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"}/me-shell`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"}/me-shell`
    readonly property string shell: Quickshell.shellDir

    function expand(path: string): string {
        return path.startsWith("~") ? home + path.slice(1) : path;
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", config, state])
}
