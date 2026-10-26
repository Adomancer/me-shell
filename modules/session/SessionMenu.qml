import QtQuick
import qs.components
import qs.services
import qs.utils

// Menu power yang menempel di tepi kanan. Aksi berbahaya harus dikonfirmasi (klik/Enter dua kali).
Item {
    id: root

    property bool shown: false
    property int current: 0
    property string pending: ""

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

    implicitWidth: col.implicitWidth + Appearance.padding.large * 2
    implicitHeight: col.implicitHeight + Appearance.padding.large * 2

    onShownChanged: {
        pending = "";
        current = 0;
        if (shown)
            col.forceActiveFocus();
    }

    Column {
        id: col

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        focus: true
        Keys.onEscapePressed: DrawerState.close()
        Keys.onUpPressed: root.move(-1)
        Keys.onDownPressed: root.move(1)
        Keys.onTabPressed: root.move(1)
        Keys.onReturnPressed: root.run(root.current)
        Keys.onEnterPressed: root.run(root.current)

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            bottomPadding: Appearance.spacing.small

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "schedule"
                color: Appearance.colors.textDim
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: UserInfo.uptime
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.small
                color: Appearance.colors.textDim
            }
        }

        Repeater {
            model: root.actions

            // Lingkaran yang membesar saat dipilih; aksi berbahaya jadi merah "Yakin?" dulu
            Item {
                id: btn

                required property var modelData
                required property int index
                readonly property bool isCurrent: root.current === index
                readonly property bool isPending: root.pending === modelData.id
                readonly property color ink: isPending ? Appearance.colors.errorText : isCurrent ? Appearance.colors.primaryText : Appearance.colors.text

                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: 76
                implicitHeight: circle.height + label.implicitHeight + 6

                StyledRect {
                    id: circle

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: btn.isCurrent || btn.isPending ? 60 : 52
                    height: width
                    radius: width / 2
                    color: btn.isPending ? Appearance.colors.error : btn.isCurrent ? Appearance.colors.primary : "transparent"
                    border.width: btn.isCurrent || btn.isPending ? 0 : 1
                    border.color: Appearance.colors.hairline

                    Behavior on width {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveFast
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: btn.isPending ? "warning" : btn.modelData.icon
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
                        onClicked: root.run(btn.index)
                    }
                }

                Caption {
                    id: label

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: circle.bottom
                    anchors.topMargin: 6
                    text: btn.isPending ? "Yakin?" : btn.modelData.label
                    color: btn.isPending ? Appearance.colors.error : btn.isCurrent ? Appearance.colors.primary : Appearance.colors.textDim
                }
            }
        }
    }
}
