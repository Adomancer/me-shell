import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Tata letak 3 kolom ala Caelestia: kiri cuaca/fetch/media, tengah jam/avatar/password, kanan resource/notif.
Item {
    id: root

    component Big: StyledText {
        color: Appearance.colors.primary
        font.pixelSize: 104
        font.bold: true
    }

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

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../../assets/scanlines.svg")
        fillMode: Image.Tile
        sourceSize: Qt.size(4, 4)
        smooth: false
        opacity: 0.35
    }

    // Input tersembunyi; yang tampil adalah bintang + kursor
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

    Item {
        id: wrap

        anchors.fill: parent
        anchors.topMargin: 36
        anchors.bottomMargin: 36
        anchors.leftMargin: 48
        anchors.rightMargin: 48

        // Efek layar CRT menyala: garis horizontal dulu, lalu melebar ke atas-bawah
        transform: Scale {
            id: crtOn

            origin.x: wrap.width / 2
            origin.y: wrap.height / 2
            xScale: 0.02
            yScale: 0.01
        }

        Component.onCompleted: powerOn.start()

        SequentialAnimation {
            id: powerOn

            NumberAnimation {
                target: crtOn
                property: "xScale"
                to: 1
                duration: Appearance.anim.duration.fast
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: crtOn
                property: "yScale"
                to: 1
                duration: Appearance.anim.duration.slow
                easing.type: Appearance.anim.easing.emphasized
            }
        }

        RetroFrame {
            id: frame

            anchors.fill: parent
            title: "locked // me-shell"
            background: Qt.rgba(Appearance.colors.surface.r, Appearance.colors.surface.g, Appearance.colors.surface.b, 0.86)

            RowLayout {
                width: wrap.width - frame.pad * 2 - frame.bw * 2 - frame.so
                height: wrap.height - 24 - frame.pad * 2 - frame.bw * 2 - frame.so
                spacing: Appearance.spacing.huge

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: Appearance.spacing.large

                    WeatherCard {
                        Layout.fillWidth: true
                    }

                    FetchCard {
                        Layout.fillWidth: true
                    }

                    LockMedia {
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 384
                    Layout.maximumWidth: 384
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Appearance.spacing.large

                    Row {
                        Layout.alignment: Qt.AlignHCenter

                        Big {
                            text: Qt.formatDateTime(Time.date, "hh")
                        }
                        Big {
                            text: ":"
                            opacity: root.cursorOn ? 1 : 0
                        }
                        Big {
                            text: Qt.formatDateTime(Time.date, "mm")
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Time.date.toLocaleString(Qt.locale(), "dddd • d MMM").toUpperCase()
                        font.pixelSize: Appearance.font.size.large
                        font.bold: true
                        font.letterSpacing: 3
                    }

                    // Avatar dari ~/.face; inisial kalau tidak ada
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Appearance.spacing.large
                        implicitWidth: 112 + Appearance.shadowOffset.normal
                        implicitHeight: 112 + Appearance.shadowOffset.normal

                        Rectangle {
                            x: Appearance.shadowOffset.normal
                            y: Appearance.shadowOffset.normal
                            width: 112
                            height: 112
                            color: Appearance.colors.shadow
                            opacity: 0.6
                        }

                        Rectangle {
                            width: 112
                            height: 112
                            color: Appearance.colors.surfaceHigh
                            border.width: Appearance.border.normal
                            border.color: Appearance.colors.primary

                            Image {
                                id: avatar

                                anchors.fill: parent
                                anchors.margins: Appearance.border.normal
                                source: `file://${UserInfo.avatar}`
                                fillMode: Image.PreserveAspectCrop
                                smooth: !Config.pixelArt
                                sourceSize: Config.pixelArt ? Qt.size(32, 32) : Qt.size(224, 224)
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: !avatar.visible
                                text: UserInfo.displayName.charAt(0).toUpperCase()
                                color: Appearance.colors.primary
                                font.pixelSize: 56
                                font.bold: true
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: UserInfo.displayName.toUpperCase()
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    RetroFrame {
                        id: box

                        property real shakeX: 0

                        Layout.fillWidth: true
                        title: "login"

                        transform: Translate {
                            x: box.shakeX
                        }

                        SequentialAnimation {
                            id: shake

                            loops: 2

                            NumberAnimation {
                                target: box
                                property: "shakeX"
                                to: 12
                                duration: 40
                            }
                            NumberAnimation {
                                target: box
                                property: "shakeX"
                                to: -12
                                duration: 80
                            }
                            NumberAnimation {
                                target: box
                                property: "shakeX"
                                to: 0
                                duration: 40
                            }
                        }

                        Column {
                            width: 384 - box.pad * 2 - box.bw * 2 - box.so
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

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    spacing: Appearance.spacing.large

                    ResourcesCard {
                        Layout.fillWidth: true
                    }

                    NotifDock {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
