import QtQuick
import qs.components
import qs.services
import qs.utils

// Tile utama: avatar, nama, kolom password, dan tombol daya.
Tile {
    id: root

    required property var lock
    readonly property bool failed: lock.failed && !lock.busy

    Connections {
        target: root.lock

        function onFailedChanged(): void {
            if (root.lock.failed)
                shake.restart();
        }
    }

    Caption {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        text: Time.greeting
        color: Appearance.colors.primary
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -12
        spacing: Appearance.spacing.normal

        // Avatar; cincin titik berputar selama password diperiksa
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 148
            height: 148

            CircularProgress {
                anchors.fill: parent
                size: 148
                thickness: 6
                value: 1
                label: ""
                opacity: root.lock.busy ? 1 : 0
                color: Appearance.colors.primary

                Behavior on opacity {
                    Anim {}
                }

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 1600
                    loops: Animation.Infinite
                    running: root.lock.busy
                }
            }

            Avatar {
                anchors.centerIn: parent
                size: 120
                source: `file://${UserInfo.avatar}`
                initial: UserInfo.displayName.charAt(0).toUpperCase()
                scale: root.lock.busy ? 0.92 : 1

                Behavior on scale {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
                }
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: UserInfo.displayName
            font.pixelSize: Appearance.font.size.extraLarge - 4
            font.weight: Font.Medium
        }

        Item {
            width: 1
            height: Appearance.spacing.small
        }

        // Kolom password
        StyledRect {
            id: box

            property real shakeX: 0

            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(360, root.width - root.pad * 4)
            height: 52
            radius: height / 2
            color: root.failed ? Appearance.alpha(Appearance.colors.error, 0.16) : Appearance.colors.surfaceContainerHigh

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
                color: root.failed ? Appearance.colors.error : Appearance.colors.textDim
            }

            // Titik dot-matrix untuk tiap karakter, meletup saat muncul
            ListView {
                anchors.left: lockIcon.right
                anchors.leftMargin: Appearance.spacing.normal
                anchors.right: submit.left
                anchors.rightMargin: Appearance.spacing.normal
                anchors.verticalCenter: parent.verticalCenter
                height: 14
                orientation: ListView.Horizontal
                spacing: 5
                interactive: false
                clip: true
                model: root.lock.password.length

                delegate: Rectangle {
                    width: 10
                    height: 10
                    radius: 5
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
                text: root.lock.busy ? "Memeriksa..." : "Password"
                color: Appearance.colors.outline
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

        Caption {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.lock.busy ? "Memeriksa" : root.lock.unlocking ? "Selamat datang kembali" : root.failed ? (root.lock.message || "Password salah") : "Enter untuk membuka"
            color: root.failed ? Appearance.colors.error : Appearance.colors.textDim
        }
    }

    // Kaki: status baterai/host di kiri, tombol daya di kanan
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: Battery.available ? (Battery.charging ? "battery_charging_full" : "battery_full") : "computer"
            font.pixelSize: Appearance.font.size.larger
            color: Appearance.colors.textDim
        }

        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: Battery.available ? `${Math.round(Battery.percentage * 100)}%` : UserInfo.host
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: Appearance.spacing.small

        IconButton {
            icon: "bedtime"
            type: "tonal"
            onClicked: Session.suspend()
        }

        IconButton {
            icon: "restart_alt"
            type: "tonal"
            onClicked: Session.reboot()
        }

        IconButton {
            icon: "power_settings_new"
            type: "tonal"
            onClicked: Session.poweroff()
        }
    }
}
