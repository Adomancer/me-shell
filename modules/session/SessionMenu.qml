import QtQuick
import qs.components
import qs.services
import qs.utils
import "../../utils/PixelIcons.js" as Icons

// Menu power yang menempel di tepi kanan layar. Masuk patah-patah ala game 8-bit,
// lalu tombolnya muncul satu per satu. Aksi berbahaya harus dikonfirmasi (klik/Enter dua kali).
Item {
    id: root

    property bool shown: false
    // Area input untuk mask window; ukurannya 0 saat tertutup
    readonly property Item hitArea: hit
    property int current: 0
    property string pending: ""
    property bool blinkOn: true

    readonly property var actions: [
        {
            id: "lock",
            label: "LOCK",
            icon: Icons.lock,
            confirm: false
        },
        {
            id: "logout",
            label: "LOGOUT",
            icon: Icons.logout,
            confirm: true
        },
        {
            id: "suspend",
            label: "SLEEP",
            icon: Icons.suspend,
            confirm: false
        },
        {
            id: "reboot",
            label: "REBOOT",
            icon: Icons.reboot,
            confirm: true
        },
        {
            id: "poweroff",
            label: "SHUTDOWN",
            icon: Icons.power,
            confirm: true
        }
    ]

    function run(i: int): void {
        const a = actions[i];
        if (a.confirm && pending !== a.id) {
            pending = a.id;
            current = i;
            return;
        }
        pending = "";
        DrawerState.close();
        switch (a.id) {
        case "lock":
            Session.lock();
            break;
        case "logout":
            Session.logout();
            break;
        case "suspend":
            Session.suspend();
            break;
        case "reboot":
            Session.reboot();
            break;
        case "poweroff":
            Session.poweroff();
            break;
        }
    }

    function move(delta: int): void {
        pending = "";
        current = (current + delta + actions.length) % actions.length;
    }

    onShownChanged: {
        pending = "";
        current = 0;
        if (shown)
            frame.forceActiveFocus();
    }

    Item {
        id: hit

        width: root.shown ? root.width : 0
        height: root.shown ? root.height : 0
    }

    Timer {
        interval: root.pending !== "" ? 250 : 530
        repeat: true
        running: root.shown
        onTriggered: root.blinkOn = !root.blinkOn
    }

    // Latar gelap + scanline
    Item {
        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.duration.normal
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.background
            opacity: 0.55
        }

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("../../assets/scanlines.svg")
            fillMode: Image.Tile
            sourceSize: Qt.size(4, 4)
            smooth: false
            opacity: 0.6
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.shown
            onClicked: DrawerState.close()
        }
    }

    Item {
        id: panel

        property real progress: root.shown ? 1 : 0
        // Dibulatkan ke 7 langkah supaya geraknya patah-patah
        readonly property real stepped: Math.round(progress * 7) / 7
        // Border kanan dan bayangan sengaja di luar layar supaya panel menempel di tepi
        readonly property real visibleWidth: width - frame.so - frame.bw

        width: frame.implicitWidth
        height: frame.implicitHeight
        anchors.verticalCenter: parent.verticalCenter
        x: root.width - visibleWidth * stepped
        visible: progress > 0

        Behavior on progress {
            NumberAnimation {
                duration: 420
            }
        }

        RetroFrame {
            id: frame

            title: root.pending !== "" ? "yakin?" : "system"
            focus: true
            Keys.onUpPressed: root.move(-1)
            Keys.onDownPressed: root.move(1)
            Keys.onReturnPressed: root.run(root.current)
            Keys.onEnterPressed: root.run(root.current)
            Keys.onEscapePressed: {
                if (root.pending !== "")
                    root.pending = "";
                else
                    DrawerState.close();
            }

            Column {
                spacing: 6
                leftPadding: Appearance.spacing.large

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Appearance.spacing.small

                    PixelIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        rows: Icons.power
                        pixel: 3
                        color: Appearance.colors.primary
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: `UP ${UserInfo.uptime}`
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                    }
                }

                Rectangle {
                    width: 120
                    height: Appearance.border.thin
                    color: Appearance.colors.outline
                }

                Repeater {
                    model: root.actions

                    StyledRect {
                        id: btn

                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: root.current === index
                        readonly property bool isPending: root.pending === modelData.id
                        readonly property color ink: isPending || isCurrent ? Appearance.colors.primaryText : Appearance.colors.text
                        // Animasi muncul, dibulatkan ke 4 langkah
                        property real progress: 0
                        readonly property real stepped: Math.round(progress * 4) / 4

                        width: 120
                        height: 76
                        color: isPending ? Appearance.colors.error : isCurrent ? Appearance.colors.primary : "transparent"
                        border.width: Appearance.border.thin
                        border.color: isPending ? Appearance.colors.error : isCurrent ? Appearance.colors.primary : Appearance.colors.outline
                        opacity: stepped

                        transform: Translate {
                            x: (1 - btn.stepped) * 32
                        }

                        SequentialAnimation {
                            id: popIn

                            PropertyAction {
                                target: btn
                                property: "progress"
                                value: 0
                            }
                            PauseAnimation {
                                duration: 380 + btn.index * 70
                            }
                            NumberAnimation {
                                target: btn
                                property: "progress"
                                to: 1
                                duration: 240
                            }
                        }

                        Connections {
                            target: root

                            function onShownChanged(): void {
                                if (root.shown)
                                    popIn.restart();
                            }
                        }

                        Component.onCompleted: {
                            if (root.shown)
                                popIn.restart();
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            PixelIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                rows: btn.modelData.icon
                                pixel: 3
                                color: btn.ink
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btn.isPending ? "YAKIN?" : btn.modelData.label
                                color: btn.ink
                                opacity: btn.isPending && !root.blinkOn ? 0 : 1
                                font.pixelSize: Appearance.font.size.small
                                font.bold: true
                                font.letterSpacing: 2
                            }
                        }

                        // Kursor ">" berkedip di sebelah kiri tombol terpilih
                        StyledText {
                            anchors.right: parent.left
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            visible: btn.isCurrent && !btn.isPending
                            opacity: root.blinkOn ? 1 : 0
                            text: ">"
                            color: Appearance.colors.primary
                            font.pixelSize: Appearance.font.size.large
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                if (root.current !== btn.index) {
                                    root.pending = "";
                                    root.current = btn.index;
                                }
                            }
                            onClicked: root.run(btn.index)
                        }
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↑↓ PILIH · ENTER"
                    color: Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                }
            }
        }
    }
}
