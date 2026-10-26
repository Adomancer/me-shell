import Quickshell
import QtQuick
import QtQuick.Effects
import qs.components
import qs.services
import qs.utils

// Lockscreen bento: wallpaper buram di belakang, grid tile di tengah (jam, cuaca, kalender, media, login,
// resource, sistem, notifikasi).
Item {
    id: root

    required property var lock
    // 0 = baru muncul / sedang membuka, 1 = tampil penuh
    property real reveal: 0
    readonly property real shown: lock.unlocking ? 0 : reveal

    Component.onCompleted: reveal = 1

    Behavior on reveal {
        Anim {
            duration: Appearance.anim.durations.extraLarge
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    // Wallpaper yang makin buram dan gelap seiring lock muncul. Jadi sumber shader CRT kalau aktif.
    Item {
        id: scene

        anchors.fill: parent

        Image {
            id: wall

            anchors.fill: parent
            source: Wallpaper.current ? `file://${Wallpaper.current}` : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        MultiEffect {
            anchors.fill: wall
            source: wall
            blurEnabled: true
            blur: root.shown
            blurMax: 64
            brightness: -0.2 * root.shown
            saturation: -0.2 * root.shown
            // Lebih besar sedikit supaya tepi buram tidak terlihat
            scale: 1 + 0.06 * root.shown
        }

        Rectangle {
            anchors.fill: parent
            opacity: root.shown
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Appearance.alpha(Appearance.colors.scrim, 0.1)
                }
                GradientStop {
                    position: 1
                    color: Appearance.alpha(Appearance.colors.scrim, 0.5)
                }
            }
        }
    }

    // Shader CRT opsional (jalankan scripts/build-shaders.sh lalu set "crtShader": true)
    Loader {
        anchors.fill: parent
        active: Config.crtShader

        sourceComponent: ShaderEffect {
            property variant source: ShaderEffectSource {
                sourceItem: scene
                hideSource: true
                live: true
            }
            property real time: 0
            property real lineCount: height / 3
            property real strength: 0.25

            fragmentShader: Qt.resolvedUrl("../../assets/shaders/crt.frag.qsb")

            NumberAnimation on time {
                from: 0
                to: 1000
                duration: 1000000
                loops: Animation.Infinite
            }
        }
    }

    // Input tersembunyi; yang tampil adalah titik-titik di kolom password
    TextInput {
        id: input

        opacity: 0
        focus: true
        enabled: !root.lock.busy
        echoMode: TextInput.Password
        onTextChanged: root.lock.password = text
        Keys.onReturnPressed: root.lock.submit()
        Keys.onEnterPressed: root.lock.submit()
        Component.onCompleted: forceActiveFocus()
    }

    Connections {
        target: root.lock

        function onPasswordChanged(): void {
            if (root.lock.password === "")
                input.text = "";
        }
    }

    // Grid bento 4 × 3; tile masuk bergiliran dan keluar saat password benar
    Item {
        id: bento

        readonly property int cols: 4
        readonly property int rows: 3
        readonly property int gap: Appearance.spacing.large
        readonly property real cellW: (width - gap * (cols - 1)) / cols
        readonly property real cellH: (height - gap * (rows - 1)) / rows
        readonly property bool leaving: root.lock.unlocking

        anchors.centerIn: parent
        width: Math.min(parent.width - 96, 1320)
        height: Math.min(parent.height - 96, 780)

        ClockTile {
            col: 0
            row: 0
            colSpan: 2
            order: 0
            leaving: bento.leaving
        }

        WeatherTile {
            col: 2
            row: 0
            order: 1
            leaving: bento.leaving
        }

        CalendarTile {
            col: 3
            row: 0
            order: 2
            leaving: bento.leaving
        }

        MediaTile {
            col: 0
            row: 1
            order: 3
            leaving: bento.leaving
        }

        AuthTile {
            col: 1
            row: 1
            colSpan: 2
            rowSpan: 2
            order: 1
            leaving: bento.leaving
            lock: root.lock
        }

        ResourcesTile {
            col: 3
            row: 1
            order: 4
            leaving: bento.leaving
        }

        SystemTile {
            col: 0
            row: 2
            order: 5
            leaving: bento.leaving
        }

        NotifsTile {
            col: 3
            row: 2
            order: 6
            leaving: bento.leaving
        }
    }
}
