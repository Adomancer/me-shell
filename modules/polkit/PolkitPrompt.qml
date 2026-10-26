import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Agen polkit bawaan: saat aplikasi minta izin admin (pkexec, GUI pengaturan sistem), dialog password
// muncul di tengah monitor yang fokus. Kalau agen lain (hyprpolkitagent, polkit-gnome) sudah jalan
// duluan, agen ini tidak terdaftar dan diam saja.
Scope {
    id: root

    readonly property AuthFlow flow: agent.flow

    PolkitAgent {
        id: agent
    }

    Variants {
        model: agent.isActive ? Quickshell.screens.filter(s => s.name === (Hyprland.focusedMonitor?.name ?? s.name)).slice(0, 1) : []

        PanelWindow {
            id: win

            required property ShellScreen modelData
            property real progress: 0

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "me-shell-polkit"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: progress = 1

            Behavior on progress {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefault
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Appearance.alpha(Appearance.colors.scrim, 0.45)
                opacity: Math.min(1, win.progress)
            }

            Elevation {
                anchors.fill: card
                radius: card.radius
                level: 3
                opacity: card.opacity
                scale: card.scale
            }

            StyledRect {
                id: card

                property real shake: 0
                // polkit tidak selalu mengirim pesan saat gagal, jadi dicatat sendiri
                property bool wrong: false
                // Password sudah dikirim, menunggu jawaban polkit
                readonly property bool busy: root.flow !== null && !root.flow.isResponseRequired

                anchors.centerIn: parent
                anchors.horizontalCenterOffset: shake
                implicitWidth: 420
                implicitHeight: col.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.radius.large
                color: Appearance.colors.surfaceContainer
                opacity: Math.min(1, win.progress)
                scale: 0.9 + win.progress * 0.1

                // Guncang saat password salah
                SequentialAnimation {
                    id: shakeAnim

                    Anim {
                        target: card
                        property: "shake"
                        to: 10
                        duration: 60
                    }
                    Anim {
                        target: card
                        property: "shake"
                        to: -8
                        duration: 60
                    }
                    Anim {
                        target: card
                        property: "shake"
                        to: 6
                        duration: 60
                    }
                    Anim {
                        target: card
                        property: "shake"
                        to: -4
                        duration: 60
                    }
                    Anim {
                        target: card
                        property: "shake"
                        to: 0
                        duration: 60
                    }
                }

                Connections {
                    target: root.flow

                    function onAuthenticationFailed(): void {
                        password.text = "";
                        card.wrong = true;
                        shakeAnim.restart();
                    }
                }

                ColumnLayout {
                    id: col

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Perisai di dalam cincin titik; cincin berputar selama password diperiksa
                    DotRing {
                        Layout.alignment: Qt.AlignHCenter
                        size: 76
                        dots: 28
                        value: card.busy ? 0.3 : card.wrong ? 1 : 0
                        spinning: card.busy
                        onColor: card.wrong ? Appearance.colors.error : Appearance.colors.primary

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: card.wrong ? "gpp_bad" : "shield_lock"
                            font.pixelSize: 30
                            color: card.wrong ? Appearance.colors.error : Appearance.colors.primary
                        }
                    }

                    Caption {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Appearance.spacing.small
                        text: "Izin admin"
                        color: Appearance.colors.primary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: root.flow?.message ?? ""
                        font.pixelSize: Appearance.font.size.larger
                        font.weight: Font.Medium
                        wrapMode: Text.Wrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        horizontalAlignment: Text.AlignHCenter
                        text: root.flow?.actionId ?? ""
                        color: Appearance.colors.outline
                        font.family: Appearance.font.family.mono
                        font.pixelSize: Appearance.font.size.small
                        elide: Text.ElideMiddle
                    }

                    // Kolom password tanpa kotak: garis bawah yang menebal dan menyala saat fokus
                    Item {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.normal
                        implicitHeight: 48

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: password.activeFocus ? 2 : 1
                            radius: 1
                            color: card.wrong ? Appearance.colors.error : password.activeFocus ? Appearance.colors.primary : Appearance.colors.hairline

                            Behavior on color {
                                CAnim {}
                            }
                        }

                        MaterialIcon {
                            id: keyIcon

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "key"
                            color: password.activeFocus ? Appearance.colors.primary : Appearance.colors.textDim
                        }

                        TextInput {
                            id: password

                            anchors.left: keyIcon.right
                            anchors.leftMargin: Appearance.spacing.normal
                            anchors.right: parent.right
                            anchors.rightMargin: Appearance.padding.large
                            anchors.verticalCenter: parent.verticalCenter
                            focus: true
                            echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                            color: Appearance.colors.text
                            font.family: Appearance.font.family.sans
                            font.pixelSize: Appearance.font.size.larger
                            font.letterSpacing: echoMode === TextInput.Password ? 4 : 0
                            passwordCharacter: "●"
                            selectionColor: Appearance.colors.primary
                            selectedTextColor: Appearance.colors.primaryText
                            clip: true
                            enabled: root.flow?.isResponseRequired ?? false
                            Keys.onReturnPressed: root.flow?.submit(text)
                            Keys.onEnterPressed: root.flow?.submit(text)
                            Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()
                            onTextEdited: card.wrong = false

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: password.text === ""
                                text: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                                color: Appearance.colors.textDim
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        horizontalAlignment: Text.AlignHCenter
                        text: root.flow?.supplementaryMessage || (card.wrong ? "Password salah, coba lagi" : "")
                        color: root.flow?.supplementaryIsError || card.wrong ? Appearance.colors.error : Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.small
                        spacing: Appearance.spacing.small

                        Item {
                            Layout.fillWidth: true
                        }

                        TextButton {
                            type: "text"
                            text: "Batal"
                            onClicked: root.flow?.cancelAuthenticationRequest()
                        }

                        TextButton {
                            type: "filled"
                            icon: "check"
                            text: "Izinkan"
                            disabled: !(root.flow?.isResponseRequired ?? false)
                            onClicked: root.flow?.submit(password.text)
                        }
                    }
                }
            }
        }
    }
}
