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

        function onFailedChanged(): void {
            if (root.lock.failed)
                shake.restart();
        }
    }

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 48
        spacing: Appearance.spacing.huge * 2
        opacity: root.shown
        scale: root.lock.unlocking ? 1.06 : 0.94 + 0.06 * root.reveal

        transform: Translate {
            y: (1 - root.reveal) * 40
        }

        Behavior on scale {
            enabled: root.lock.unlocking

            Anim {
                duration: Appearance.anim.durations.large
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.spacing.normal

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
            Layout.preferredWidth: 400
            Layout.maximumWidth: 400
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(Time.date, "hh:mm")
                color: Appearance.colors.primary
                font.family: Appearance.font.family.mono
                font.pixelSize: 120
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -Appearance.spacing.normal
                text: Time.date.toLocaleString(Qt.locale(), "dddd, d MMMM")
                color: Appearance.colors.text
                font.pixelSize: Appearance.font.size.large
            }

            // Avatar dengan cincin; cincin berputar selama password diperiksa
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.huge * 2
                implicitWidth: 132
                implicitHeight: 132

                CircularProgress {
                    anchors.fill: parent
                    size: 132
                    thickness: 4
                    value: 0.75
                    label: ""
                    visible: root.lock.busy
                    color: Appearance.colors.primary

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                        running: root.lock.busy
                    }
                }

                Avatar {
                    anchors.centerIn: parent
                    size: 116
                    source: `file://${UserInfo.avatar}`
                    initial: UserInfo.displayName.charAt(0).toUpperCase()
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                text: UserInfo.displayName
                font.pixelSize: Appearance.font.size.large
                font.weight: Font.Medium
            }

            // Kolom password
            StyledRect {
                id: box

                property real shakeX: 0

                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                implicitHeight: 56
                radius: height / 2
                color: Appearance.alpha(Appearance.colors.surfaceContainer, 0.85)
                border.width: root.lock.failed && !root.lock.busy ? 2 : 0
                border.color: Appearance.colors.error

                transform: Translate {
                    x: box.shakeX
                }

                SequentialAnimation {
                    id: shake

                    Anim {
                        target: box
                        property: "shakeX"
                        to: 14
                        duration: 60
                    }
                    Anim {
                        target: box
                        property: "shakeX"
                        to: -10
                        duration: 90
                    }
                    Anim {
                        target: box
                        property: "shakeX"
                        to: 6
                        duration: 90
                    }
                    Anim {
                        target: box
                        property: "shakeX"
                        to: 0
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                    }
                }

                MaterialIcon {
                    id: lockIcon

                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.padding.large
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.lock.unlocking ? "lock_open" : "lock"
                    fill: 1
                    color: Appearance.colors.textDim
                }

                // Titik untuk tiap karakter, meletup saat muncul
                ListView {
                    anchors.left: lockIcon.right
                    anchors.leftMargin: Appearance.spacing.normal
                    anchors.right: submit.left
                    anchors.rightMargin: Appearance.spacing.normal
                    anchors.verticalCenter: parent.verticalCenter
                    height: 16
                    orientation: ListView.Horizontal
                    spacing: 6
                    interactive: false
                    clip: true
                    model: root.lock.password.length

                    delegate: Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        anchors.verticalCenter: parent?.verticalCenter
                        color: Appearance.colors.text
                    }

                    add: Transition {
                        Anim {
                            property: "scale"
                            from: 0
                            to: 1
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveFast
                        }
                    }
                    remove: Transition {
                        Anim {
                            property: "scale"
                            to: 0
                            duration: Appearance.anim.durations.small
                        }
                    }
                }

                StyledText {
                    anchors.left: lockIcon.right
                    anchors.leftMargin: Appearance.spacing.normal
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.lock.password === ""
                    text: root.lock.busy ? "Memeriksa..." : root.lock.message !== "" ? root.lock.message : "Masukkan password"
                    color: root.lock.failed && !root.lock.busy ? Appearance.colors.error : Appearance.colors.textDim
                }

                IconButton {
                    id: submit

                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "arrow_forward"
                    type: "filled"
                    toggled: root.lock.password !== ""
                    padding: Appearance.padding.small + 3
                    disabled: root.lock.busy
                    onClicked: root.lock.submit()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            spacing: Appearance.spacing.normal

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
