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

                    StyledRect {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 56
                        implicitHeight: 56
                        radius: Appearance.radius.normal
                        color: Appearance.colors.primaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "admin_panel_settings"
                            fill: 1
                            font.pixelSize: Appearance.font.size.extraLarge
                            color: Appearance.colors.primaryContainerText
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Butuh izin admin"
                        font.pixelSize: Appearance.font.size.large
                        font.weight: Font.Medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: root.flow?.message ?? ""
                        color: Appearance.colors.textDim
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

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.small
                        implicitHeight: 48
                        radius: height / 2
                        color: Appearance.colors.surfaceContainerHighest
                        border.width: password.activeFocus ? 2 : 0
                        border.color: Appearance.colors.primary

                        MaterialIcon {
                            id: keyIcon

                            anchors.left: parent.left
                            anchors.leftMargin: Appearance.padding.normal + 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: "key"
                            color: Appearance.colors.primary
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
