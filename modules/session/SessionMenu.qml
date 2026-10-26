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

            StyledRect {
                id: btn

                required property var modelData
                required property int index
                readonly property bool isCurrent: root.current === index
                readonly property bool isPending: root.pending === modelData.id
                readonly property color ink: isPending ? Appearance.colors.errorContainerText : isCurrent ? Appearance.colors.primaryContainerText : Appearance.colors.text

                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: 76
                implicitHeight: isCurrent ? 76 : 64
                radius: isCurrent ? Appearance.radius.large : Appearance.radius.small
                color: isPending ? Appearance.colors.errorContainer : isCurrent ? Appearance.colors.primaryContainer : Appearance.colors.surfaceContainerHigh

                Behavior on implicitHeight {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
                }
                Behavior on radius {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.isPending ? "warning" : btn.modelData.icon
                        font.pixelSize: btn.isCurrent ? 28 : 24
                        fill: btn.isCurrent ? 1 : 0
                        color: btn.ink

                        Behavior on font.pixelSize {
                            Anim {
                                duration: Appearance.anim.durations.expressiveFast
                                easing.bezierCurve: Appearance.anim.curves.expressiveFast
                            }
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.isPending ? "Yakin?" : btn.modelData.label
                        font.pixelSize: Appearance.font.size.small
                        color: btn.ink
                        opacity: btn.isCurrent || btn.isPending ? 1 : 0.8
                    }
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
        }
    }
}
