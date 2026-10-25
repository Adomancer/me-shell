pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.utils

// Design tokens. Semua module WAJIB ambil warna/ukuran/animasi dari sini.
Singleton {
    id: root

    // Warna dengan alpha baru, misalnya untuk state layer dan bayangan
    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // Peran warna Material 3 dari matugen (scripts/gen-colors.sh). Fallback = palet amber.
    readonly property QtObject colors: QtObject {
        readonly property color background: scheme.background || "#18120c"
        readonly property color surface: scheme.surface || "#18120c"
        readonly property color surfaceDim: scheme.surfaceDim || "#18120c"
        readonly property color surfaceBright: scheme.surfaceBright || "#403830"
        readonly property color surfaceContainerLowest: scheme.surfaceContainerLowest || "#130d07"
        readonly property color surfaceContainerLow: scheme.surfaceContainerLow || "#211a13"
        readonly property color surfaceContainer: scheme.surfaceContainer || "#251e17"
        readonly property color surfaceContainerHigh: scheme.surfaceContainerHigh || "#302921"
        readonly property color surfaceContainerHighest: scheme.surfaceContainerHighest || "#3b332b"
        readonly property color surfaceVariant: scheme.surfaceVariant || "#504539"
        readonly property color text: scheme.text || "#eee0d4"
        readonly property color textDim: scheme.textDim || "#d4c4b5"
        readonly property color outline: scheme.outline || "#9c8e80"
        readonly property color outlineVariant: scheme.outlineVariant || "#504539"
        readonly property color primary: scheme.primary || "#f8bb71"
        readonly property color primaryText: scheme.primaryText || "#472a00"
        readonly property color primaryContainer: scheme.primaryContainer || "#653e00"
        readonly property color primaryContainerText: scheme.primaryContainerText || "#ffddb8"
        readonly property color secondary: scheme.secondary || "#dfc2a2"
        readonly property color secondaryText: scheme.secondaryText || "#3f2d17"
        readonly property color secondaryContainer: scheme.secondaryContainer || "#57432b"
        readonly property color secondaryContainerText: scheme.secondaryContainerText || "#fcddbd"
        readonly property color tertiary: scheme.tertiary || "#bbcd9e"
        readonly property color tertiaryText: scheme.tertiaryText || "#273513"
        readonly property color tertiaryContainer: scheme.tertiaryContainer || "#3d4c28"
        readonly property color tertiaryContainerText: scheme.tertiaryContainerText || "#d7e9b8"
        readonly property color error: scheme.error || "#ffb4ab"
        readonly property color errorText: scheme.errorText || "#690005"
        readonly property color errorContainer: scheme.errorContainer || "#93000a"
        readonly property color errorContainerText: scheme.errorContainerText || "#ffdad6"
        readonly property color inverseSurface: scheme.inverseSurface || "#eee0d4"
        readonly property color inverseText: scheme.inverseText || "#372f27"
        readonly property color inversePrimary: scheme.inversePrimary || "#825513"
        readonly property color shadow: scheme.shadow || "#000000"
        readonly property color scrim: scheme.scrim || "#000000"
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string sans: Config.fontSans
            // Angka, jam, dan statistik (aksen retro)
            readonly property string mono: Config.fontFamily
            readonly property string icon: "Material Symbols Rounded"
        }
        readonly property QtObject size: QtObject {
            readonly property int small: 11
            readonly property int smaller: 12
            readonly property int normal: 13
            readonly property int larger: 15
            readonly property int large: 18
            readonly property int extraLarge: 28
            readonly property int huge: 48
            readonly property int giant: 112
        }
    }

    readonly property QtObject spacing: QtObject {
        readonly property int small: 6
        readonly property int normal: 10
        readonly property int large: 14
        readonly property int huge: 20
    }

    readonly property QtObject padding: QtObject {
        readonly property int small: 6
        readonly property int normal: 12
        readonly property int large: 18
    }

    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int small: 10
        readonly property int normal: 16
        readonly property int large: 24
        readonly property int full: 1000
    }

    readonly property QtObject border: QtObject {
        readonly property int thin: 1
        readonly property int normal: 2
    }

    // Bingkai di sekeliling layar tempat bar dan drawer menempel
    readonly property QtObject frame: QtObject {
        readonly property int thickness: Config.frameEnabled ? Config.frameThickness : 0
        readonly property int rounding: 24
    }

    readonly property QtObject anim: QtObject {
        // Dikali sesuai setting "Kecepatan animasi"
        readonly property real speed: ({
                cepat: 0.6,
                normal: 1,
                lambat: 1.6
            })[Config.animSpeed] ?? 1

        // Kurva Material 3 untuk Easing.BezierSpline
        readonly property QtObject curves: QtObject {
            readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
            readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
            readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
            readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
            readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
            readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
            // Sedikit melewati target lalu kembali (pegas)
            readonly property list<real> expressiveFast: [0.42, 1.67, 0.21, 0.9, 1, 1]
            readonly property list<real> expressiveDefault: [0.38, 1.21, 0.22, 1, 1, 1]
            readonly property list<real> expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        }

        readonly property QtObject durations: QtObject {
            readonly property int small: Math.round(200 * root.anim.speed)
            readonly property int normal: Math.round(400 * root.anim.speed)
            readonly property int large: Math.round(600 * root.anim.speed)
            readonly property int extraLarge: Math.round(1000 * root.anim.speed)
            readonly property int expressiveFast: Math.round(350 * root.anim.speed)
            readonly property int expressiveDefault: Math.round(500 * root.anim.speed)
            readonly property int expressiveEffects: Math.round(200 * root.anim.speed)
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
            property string surfaceDim: ""
            property string surfaceBright: ""
            property string surfaceContainerLowest: ""
            property string surfaceContainerLow: ""
            property string surfaceContainer: ""
            property string surfaceContainerHigh: ""
            property string surfaceContainerHighest: ""
            property string surfaceVariant: ""
            property string text: ""
            property string textDim: ""
            property string outline: ""
            property string outlineVariant: ""
            property string primary: ""
            property string primaryText: ""
            property string primaryContainer: ""
            property string primaryContainerText: ""
            property string secondary: ""
            property string secondaryText: ""
            property string secondaryContainer: ""
            property string secondaryContainerText: ""
            property string tertiary: ""
            property string tertiaryText: ""
            property string tertiaryContainer: ""
            property string tertiaryContainerText: ""
            property string error: ""
            property string errorText: ""
            property string errorContainer: ""
            property string errorContainerText: ""
            property string inverseSurface: ""
            property string inverseText: ""
            property string inversePrimary: ""
            property string shadow: ""
            property string scrim: ""
        }
    }
}
