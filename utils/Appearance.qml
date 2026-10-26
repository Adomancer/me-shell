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

    // Saturasi dikurangi supaya permukaan dan teks hampir netral (monokrom ala Nothing/TE).
    // Qt.lighter(x, 1) mengubah string warna jadi color.
    function neutral(c: var): color {
        const q = Qt.lighter(c, 1);
        return Qt.hsla(Math.max(0, q.hslHue), q.hslSaturation * 0.2, q.hslLightness, q.a);
    }

    // Peran warna dari matugen (scripts/gen-colors.sh). Fallback = palet amber.
    // Gaya Nothing/TE: permukaan dan teks hampir netral + SATU warna aksen (primary). Peran secondary,
    // tertiary, dan container dipetakan ke netral/aksen di sini, jadi module tidak perlu tahu.
    readonly property QtObject colors: QtObject {
        readonly property color background: root.neutral(scheme.background || "#18120c")
        readonly property color surface: root.neutral(scheme.surface || "#18120c")
        readonly property color surfaceDim: root.neutral(scheme.surfaceDim || "#18120c")
        readonly property color surfaceBright: root.neutral(scheme.surfaceBright || "#403830")
        readonly property color surfaceContainerLowest: root.neutral(scheme.surfaceContainerLowest || "#130d07")
        readonly property color surfaceContainerLow: root.neutral(scheme.surfaceContainerLow || "#211a13")
        readonly property color surfaceContainer: root.neutral(scheme.surfaceContainer || "#251e17")
        readonly property color surfaceContainerHigh: root.neutral(scheme.surfaceContainerHigh || "#302921")
        readonly property color surfaceContainerHighest: root.neutral(scheme.surfaceContainerHighest || "#3b332b")
        readonly property color surfaceVariant: root.neutral(scheme.surfaceVariant || "#504539")
        readonly property color text: root.neutral(scheme.text || "#eee0d4")
        readonly property color textDim: root.neutral(scheme.textDim || "#d4c4b5")
        readonly property color outline: root.neutral(scheme.outline || "#9c8e80")
        readonly property color outlineVariant: root.neutral(scheme.outlineVariant || "#504539")
        readonly property color primary: scheme.primary || "#f8bb71"
        readonly property color primaryText: scheme.primaryText || "#472a00"
        readonly property color primaryContainer: surfaceContainerHighest
        readonly property color primaryContainerText: scheme.primary || "#f8bb71"
        readonly property color secondary: text
        readonly property color secondaryText: surface
        readonly property color secondaryContainer: surfaceContainerHighest
        readonly property color secondaryContainerText: scheme.primary || "#f8bb71"
        readonly property color tertiary: scheme.primary || "#f8bb71"
        readonly property color tertiaryText: scheme.primaryText || "#472a00"
        readonly property color tertiaryContainer: surfaceContainerHighest
        readonly property color tertiaryContainerText: scheme.primary || "#f8bb71"
        readonly property color error: scheme.error || "#ffb4ab"
        readonly property color errorText: scheme.errorText || "#690005"
        readonly property color errorContainer: scheme.errorContainer || "#93000a"
        readonly property color errorContainerText: scheme.errorContainerText || "#ffdad6"
        readonly property color inverseSurface: scheme.inverseSurface || "#eee0d4"
        readonly property color inverseText: scheme.inverseText || "#372f27"
        readonly property color inversePrimary: scheme.inversePrimary || "#825513"
        readonly property color shadow: scheme.shadow || "#000000"
        readonly property color scrim: scheme.scrim || "#000000"
        // Garis pemisah tipis (Divider, cincin tipis tombol)
        readonly property color hairline: Qt.rgba(outlineVariant.r, outlineVariant.g, outlineVariant.b, 0.8)
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string sans: Config.fontSans
            // Angka, jam, dan statistik (aksen retro)
            readonly property string mono: Config.fontFamily
            readonly property string icon: "Material Symbols Rounded"
            // Judul dan label kecil ikut mono (aksen retro)
            readonly property string title: Config.fontFamily
            // Angka besar (jam, persen): dot-matrix
            readonly property string display: Config.fontDisplay
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
        // Lembut, bukan kotak; full untuk tombol bulat dan pil
        readonly property int small: 6
        readonly property int normal: 12
        readonly property int large: 20
        readonly property int full: 1000
    }

    readonly property QtObject border: QtObject {
        readonly property int thin: 1
        readonly property int normal: 2
    }

    // Bingkai di sekeliling layar tempat bar dan drawer menempel
    readonly property QtObject frame: QtObject {
        readonly property int thickness: Config.frameEnabled ? Config.frameThickness : 0
        readonly property int rounding: 16
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
