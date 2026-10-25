pragma Singleton

import Quickshell
import QtQuick

// Design tokens. Semua module WAJIB ambil warna/ukuran/animasi dari sini.
Singleton {
    id: root

    // Placeholder palet retro (amber di atas gelap hangat).
    // Nanti diganti hasil matugen dari wallpaper.
    readonly property QtObject colors: QtObject {
        readonly property color background: "#12100e"
        readonly property color surface: "#1c1915"
        readonly property color surfaceHigh: "#27231d"
        readonly property color outline: "#3a342c"
        readonly property color text: "#e8dcc4"
        readonly property color textDim: "#9a8f7c"
        readonly property color primary: "#e0a458"
        readonly property color onPrimary: "#12100e"
        readonly property color error: "#d9614f"
        readonly property color shadow: "#000000"
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            // Ganti ke "Departure Mono" kalau sudah terinstall
            readonly property string mono: "JetBrains Mono"
            readonly property string sans: "Inter"
        }
        readonly property QtObject size: QtObject {
            readonly property int small: 11
            readonly property int normal: 13
            readonly property int large: 16
            readonly property int huge: 48
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
        readonly property QtObject duration: QtObject {
            readonly property int fast: 120
            readonly property int normal: 220
            readonly property int slow: 400
        }
        readonly property QtObject easing: QtObject {
            readonly property int standard: Easing.OutCubic
            readonly property int emphasized: Easing.OutBack
        }
    }
}
