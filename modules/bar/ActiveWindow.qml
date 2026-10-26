import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.components
import qs.utils

// Ikon + judul window aktif. Saat window berganti, judul lama turun memudar lalu yang baru naik.
// Hover = popout pratinjau window.
Item {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string title: toplevel?.title ?? ""
    readonly property string appId: toplevel?.appId ?? ""
    readonly property var entry: appId ? DesktopEntries.heuristicLookup(appId) : null
    property string shownTitle: title
    property string shownIcon: entry?.icon ?? ""

    implicitWidth: label.implicitWidth
    implicitHeight: Math.max(label.implicitHeight, Config.barHeight - 10)

    onTitleChanged: swap.restart()

    SequentialAnimation {
        id: swap

        ParallelAnimation {
            Anim {
                target: label
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
            }
            Anim {
                target: shift
                property: "y"
                to: 6
                duration: Appearance.anim.durations.small
            }
        }
        ScriptAction {
            script: {
                root.shownTitle = root.title;
                root.shownIcon = root.entry?.icon ?? "";
                shift.y = -6;
            }
        }
        ParallelAnimation {
            Anim {
                target: label
                property: "opacity"
                to: 1
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
            Anim {
                target: shift
                property: "y"
                to: 0
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        }
    }

    Item {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: inner.implicitWidth
        implicitHeight: inner.implicitHeight

        transform: Translate {
            id: shift
        }

        Row {
            id: inner

            spacing: Appearance.spacing.small

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.shownTitle !== "" && source !== ""
                implicitSize: 18
                // true = string kosong kalau ikon tidak ada di tema
                source: root.shownIcon ? Quickshell.iconPath(root.shownIcon, true) : ""
                asynchronous: true
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 300)
                elide: Text.ElideRight
                text: root.shownTitle
                color: Appearance.colors.textDim
            }
        }
    }

    StateLayer {
        anchors.margins: -4
        radius: height / 2
        onClicked: trigger.pin()
    }

    PopoutTrigger {
        id: trigger

        popout: "window"
    }
}
