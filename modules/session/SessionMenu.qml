import QtQuick
import qs.components
import qs.services
import qs.utils

// Menu power. Aksi berbahaya harus dikonfirmasi (klik/Enter dua kali).
Item {
    id: root

    property bool shown: false
    // Area input untuk mask window; ukurannya 0 saat tertutup
    readonly property Item hitArea: hit
    property int current: 0
    property string pending: ""

    readonly property var actions: [
        {
            id: "lock",
            label: "LOCK",
            confirm: false
        },
        {
            id: "logout",
            label: "LOGOUT",
            confirm: true
        },
        {
            id: "suspend",
            label: "SLEEP",
            confirm: false
        },
        {
            id: "reboot",
            label: "REBOOT",
            confirm: true
        },
        {
            id: "poweroff",
            label: "SHUTDOWN",
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

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.background
        opacity: root.shown ? 0.7 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.duration.normal
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.shown
            onClicked: DrawerState.close()
        }
    }

    Reveal {
        anchors.centerIn: parent
        edge: "center"
        shown: root.shown

        RetroFrame {
            id: frame

            title: root.pending !== "" ? "yakin?" : "session"
            focus: true
            Keys.onEscapePressed: {
                if (root.pending !== "")
                    root.pending = "";
                else
                    DrawerState.close();
            }
            Keys.onLeftPressed: root.current = (root.current + root.actions.length - 1) % root.actions.length
            Keys.onRightPressed: root.current = (root.current + 1) % root.actions.length
            Keys.onReturnPressed: root.run(root.current)
            Keys.onEnterPressed: root.run(root.current)

            Row {
                spacing: Appearance.spacing.normal

                Repeater {
                    model: root.actions

                    RetroButton {
                        required property var modelData
                        required property int index

                        implicitWidth: 112
                        implicitHeight: 64
                        text: root.pending === modelData.id ? `${modelData.label}?` : modelData.label
                        active: root.current === index
                        onHoveredChanged: {
                            if (hovered)
                                root.current = index;
                        }
                        onClicked: root.run(index)
                    }
                }
            }
        }
    }
}
