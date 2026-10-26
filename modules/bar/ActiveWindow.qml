import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.utils

// Nama app (label mono) + judul window aktif. Saat window berganti, judul lama turun memudar lalu yang baru naik.
// Hover = popout pratinjau window.
Item {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string title: toplevel?.title ?? ""
    readonly property string appId: toplevel?.appId ?? ""
    readonly property var entry: appId ? DesktopEntries.heuristicLookup(appId) : null
    property string shownTitle: title
    property string shownApp: entry?.name ?? appId

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
                root.shownApp = root.entry?.name ?? root.appId;
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

            Caption {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.shownTitle !== ""
                text: root.shownApp
                color: Appearance.colors.text
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 280)
                elide: Text.ElideRight
                text: root.shownTitle
                color: Appearance.colors.textDim
            }
        }
    }

    StateLayer {
        anchors.margins: -6
        radius: height / 2
        onClicked: trigger.pin()
    }

    PopoutTrigger {
        id: trigger

        popout: "window"
    }
}
