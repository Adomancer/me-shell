import QtQuick
import qs.components
import qs.services
import qs.utils

// Menu power yang menempel di tepi kanan. Aksi berbahaya harus ditahan (mouse atau Enter) sampai cincin
// titik di sekelilingnya penuh; dilepas lebih awal = batal.
Item {
    id: root

    property bool shown: false
    property int current: 0
    // Aksi yang sedang ditahan dan progresnya (0..1)
    property string holding: ""
    property real hold: 0
    readonly property int holdTime: 900

    readonly property var actions: [
        {
            id: "lock",
            label: "Kunci",
            icon: "lock",
            confirm: false
        },
        {
            id: "logout",
            label: "Keluar",
            icon: "logout",
            confirm: true
        },
        {
            id: "suspend",
            label: "Tidur",
            icon: "bedtime",
            confirm: false
        },
        {
            id: "reboot",
            label: "Restart",
            icon: "restart_alt",
            confirm: true
        },
        {
            id: "poweroff",
            label: "Matikan",
            icon: "power_settings_new",
            confirm: true
        }
    ]

    // Mulai menahan; aksi tanpa konfirmasi langsung jalan
    function press(i: int): void {
        current = i;
        if (!actions[i].confirm) {
            run(i);
            return;
        }
        holding = actions[i].id;
        cancelAnim.stop();
        // Lanjut dari sisa cincin kalau baru saja dilepas
        holdAnim.duration = Math.max(1, holdTime * (1 - hold));
        holdAnim.restart();
    }

    function release(): void {
        if (holding === "")
            return;
        holding = "";
        holdAnim.stop();
        cancelAnim.restart();
    }

    function run(i: int): void {
        holding = "";
        hold = 0;
        DrawerState.close();
        switch (actions[i].id) {
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
        release();
        current = (current + delta + actions.length) % actions.length;
    }

    implicitWidth: col.implicitWidth + Appearance.padding.large * 2
    implicitHeight: col.implicitHeight + Appearance.padding.large * 2

    onShownChanged: {
        holdAnim.stop();
        holding = "";
        hold = 0;
        current = 0;
        if (shown)
            col.forceActiveFocus();
    }

    Column {
        id: col

        anchors.centerIn: parent
        spacing: Appearance.spacing.small
        focus: true
        Keys.onEscapePressed: DrawerState.close()
        Keys.onUpPressed: root.move(-1)
        Keys.onDownPressed: root.move(1)
        Keys.onTabPressed: root.move(1)
        Keys.onPressed: event => {
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !event.isAutoRepeat) {
                root.press(root.current);
                event.accepted = true;
            }
        }
        Keys.onReleased: event => {
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !event.isAutoRepeat) {
                root.release();
                event.accepted = true;
            }
        }

        // Jam dot-matrix bertumpuk + uptime
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
            bottomPadding: Appearance.spacing.normal

            DisplayText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(Time.date, "hh")
                weight: 800
                font.pixelSize: 30
            }

            DisplayText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(Time.date, "mm")
                color: Appearance.colors.primary
                weight: 800
                font.pixelSize: 30
            }

            Caption {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: Appearance.spacing.small
                bottomPadding: Appearance.spacing.normal
                text: `Up ${UserInfo.uptime}`
                font.letterSpacing: 1
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 24
                height: 1
                color: Appearance.colors.hairline
            }
        }

        Repeater {
            model: root.actions

            // Lingkaran yang membesar saat dipilih; aksi berbahaya dikelilingi cincin titik yang terisi saat ditahan
            Item {
                id: btn

                required property var modelData
                required property int index
                readonly property bool isCurrent: root.current === index
                readonly property bool isHolding: root.holding === modelData.id
                readonly property bool danger: isCurrent && modelData.confirm
                readonly property real fill: danger ? root.hold : 0
                readonly property color ink: isCurrent ? (modelData.confirm ? Appearance.colors.errorText : Appearance.colors.primaryText) : Appearance.colors.text

                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: 84
                implicitHeight: ring.height + label.implicitHeight + 2

                // Cincin titik konfirmasi
                Item {
                    id: ring

                    readonly property int dots: 20

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 72
                    height: 72
                    opacity: btn.danger ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }

                    Repeater {
                        model: ring.dots

                        Rectangle {
                            required property int index
                            readonly property real angle: (-90 + 360 * index / ring.dots) * Math.PI / 180
                            readonly property bool lit: index < Math.round(btn.fill * ring.dots)

                            x: ring.width / 2 + 33 * Math.cos(angle) - width / 2
                            y: ring.height / 2 + 33 * Math.sin(angle) - height / 2
                            width: 4
                            height: 4
                            radius: 2
                            scale: lit ? 1.4 : 1
                            color: lit ? Appearance.colors.error : Appearance.colors.hairline
                        }
                    }
                }

                StyledRect {
                    id: circle

                    anchors.centerIn: ring
                    width: btn.isCurrent ? 56 : 50
                    height: width
                    radius: width / 2
                    color: btn.isCurrent ? (btn.modelData.confirm ? Appearance.colors.error : Appearance.colors.primary) : "transparent"
                    border.width: btn.isCurrent ? 0 : 1
                    border.color: Appearance.colors.hairline
                    scale: btn.isHolding ? 0.88 : 1

                    Behavior on width {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveFast
                        }
                    }
                    Behavior on scale {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveFast
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: btn.modelData.icon
                        font.pixelSize: 24
                        fill: btn.isCurrent ? 1 : 0
                        color: btn.ink
                    }

                    StateLayer {
                        color: btn.ink
                        onEntered: {
                            if (root.current !== btn.index)
                                root.move(btn.index - root.current);
                        }
                        onPressed: root.press(btn.index)
                        onReleased: root.release()
                        onCanceled: root.release()
                    }
                }

                Caption {
                    id: label

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: ring.bottom
                    anchors.topMargin: -2
                    text: btn.isHolding ? `${Math.round(root.hold * 100)}%` : btn.danger ? "Tahan" : btn.modelData.label
                    color: btn.isCurrent ? (btn.modelData.confirm ? Appearance.colors.error : Appearance.colors.primary) : Appearance.colors.textDim
                }
            }
        }
    }

    // Isi cincin selama ditahan; penuh = jalankan
    NumberAnimation {
        id: holdAnim

        target: root
        property: "hold"
        to: 1
        duration: root.holdTime
        onFinished: {
            if (root.holding !== "")
                root.run(root.current);
        }
    }

    // Dilepas lebih awal: cincin kosong lagi
    Anim {
        id: cancelAnim

        target: root
        property: "hold"
        to: 0
        duration: Appearance.anim.durations.normal
        easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
    }
}
