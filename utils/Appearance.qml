pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Design tokens. Semua module WAJIB ambil warna/ukuran/animasi dari sini.
Singleton {
    id: root

    // Warna dari matugen (scripts/gen-colors.sh), fallback ke palet retro amber.
    readonly property QtObject colors: QtObject {
        readonly property color background: scheme.background || "#12100e"
        readonly property color surface: scheme.surface || "#1c1915"
        readonly property color surfaceHigh: scheme.surfaceHigh || "#27231d"
        readonly property color outline: scheme.outline || "#3a342c"
        readonly property color text: scheme.text || "#e8dcc4"
        readonly property color textDim: scheme.textDim || "#9a8f7c"
        readonly property color primary: scheme.primary || "#e0a458"
        readonly property color onPrimary: scheme.onPrimary || "#12100e"
        readonly property color error: scheme.error || "#d9614f"
        readonly property color shadow: "#000000"
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string mono: Config.fontFamily
        }
        readonly property QtObject size: QtObject {
            readonly property int small: 11
            readonly property int normal: 13
            readonly property int large: 16
            readonly property int huge: 48
            readonly property int giant: 112
        }
    }

    readonly property QtObject spacing: QtObject {
        readonly property int small: 4
        readonly property int normal: 8
        readonly property int large: 12
        readonly property int huge: 20
    }

    // Retro: sudut tajam, bukan bulat
    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int small: 2
        readonly property int normal: 4
    }

    readonly property QtObject border: QtObject {
        readonly property int thin: 1
        readonly property int normal: 2
    }

    // Bayangan keras (offset tanpa blur)
    readonly property QtObject shadowOffset: QtObject {
        readonly property int small: 2
        readonly property int normal: 4
    }

    readonly property QtObject anim: QtObject {
        // Dikali sesuai setting "Kecepatan animasi"
        readonly property real speed: ({
                cepat: 0.55,
                normal: 1,
                lambat: 1.75
            })[Config.animSpeed] ?? 1
        readonly property QtObject duration: QtObject {
            readonly property int fast: Math.round(120 * root.anim.speed)
            readonly property int normal: Math.round(220 * root.anim.speed)
            readonly property int slow: Math.round(400 * root.anim.speed)
        }
        readonly property QtObject easing: QtObject {
            readonly property int standard: Easing.OutCubic
            readonly property int emphasized: Easing.OutBack
        }
    }

    FileView {
        path: `${Paths.state}/colors.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: scheme

            property string background: ""
            property string surface: ""
            property string surfaceHigh: ""
            property string outline: ""
            property string text: ""
            property string textDim: ""
            property string primary: ""
            property string onPrimary: ""
            property string error: ""
        }
    }
}
