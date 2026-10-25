import Quickshell
import QtQuick
import QtQuick.Effects
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var lock
    property bool cursorOn: true

    // Wallpaper blur + gelap. Jadi sumber untuk shader CRT kalau diaktifkan.
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
            blur: 1
            blurMax: 64
            brightness: -0.35
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

    // Scanline statis (selalu ada, ringan)
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../../assets/scanlines.svg")
        fillMode: Image.Tile
        sourceSize: Qt.size(4, 4)
        smooth: false
        opacity: 0.35
    }

    // Input tersembunyi; yang tampil adalah bintang + kursor di bawah
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

        function onFailedChanged(): void {
            if (root.lock.failed)
                shake.restart();
        }
    }

    Timer {
        interval: 530
        repeat: true
        running: true
        onTriggered: root.cursorOn = !root.cursorOn
    }

    Column {
        id: content

        anchors.centerIn: parent
        spacing: Appearance.spacing.huge

        // Efek layar CRT menyala saat lockscreen muncul
        transform: Scale {
            id: crtOn

            origin.x: content.width / 2
            origin.y: content.height / 2
            yScale: 0.01
        }

        Component.onCompleted: powerOn.start()

        SequentialAnimation {
            id: powerOn

            NumberAnimation {
                target: crtOn
                property: "yScale"
                from: 0.01
                to: 1
                duration: Appearance.anim.duration.slow
                easing.type: Appearance.anim.easing.emphasized
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.time
            color: Appearance.colors.primary
            font.pixelSize: Appearance.font.size.giant
            font.bold: true
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.dateText.toUpperCase()
            font.pixelSize: Appearance.font.size.large
            font.letterSpacing: 4
        }

        Item {
            width: 1
            height: Appearance.spacing.huge
        }

        RetroFrame {
            id: box

            anchors.horizontalCenter: parent.horizontalCenter
            title: `login: ${Quickshell.env("USER")}`

            SequentialAnimation {
                id: shake

                loops: 2

                NumberAnimation {
                    target: box
                    property: "anchors.horizontalCenterOffset"
                    to: 12
                    duration: 40
                }
                NumberAnimation {
                    target: box
                    property: "anchors.horizontalCenterOffset"
                    to: -12
                    duration: 80
                }
                NumberAnimation {
                    target: box
                    property: "anchors.horizontalCenterOffset"
                    to: 0
                    duration: 40
                }
            }

            Column {
                width: 360
                spacing: Appearance.spacing.normal

                Row {
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: "password>"
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.large
                    }

                    StyledText {
                        text: "*".repeat(Math.min(root.lock.password.length, 20))
                        font.pixelSize: Appearance.font.size.large
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: Appearance.font.size.large + 4
                        color: Appearance.colors.primary
                        opacity: root.cursorOn && !root.lock.busy ? 1 : 0
                    }
                }

                StyledText {
                    text: root.lock.busy ? "MEMERIKSA..." : root.lock.message !== "" ? root.lock.message : "TEKAN ENTER UNTUK MASUK"
                    color: root.lock.failed && !root.lock.busy ? Appearance.colors.error : Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                    font.bold: true
                }
            }
        }
    }

    StyledText {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Appearance.spacing.huge * 2
        visible: Media.active !== null && (Media.active.trackTitle ?? "") !== ""
        text: `♪ ${Media.active?.trackTitle ?? ""}${Media.active?.trackArtist ? " - " + Media.active.trackArtist : ""}`
        color: Appearance.colors.textDim
    }
}
