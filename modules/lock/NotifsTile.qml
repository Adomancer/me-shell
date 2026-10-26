import Quickshell
import QtQuick
import qs.components
import qs.services
import qs.utils

// Jumlah notifikasi (dot-matrix) + beberapa yang terbaru.
Tile {
    id: root

    readonly property var latest: [...Notifs.list].reverse()

    Caption {
        anchors.left: parent.left
        anchors.top: parent.top
        text: "Notifikasi"
    }

    DisplayText {
        id: total

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -8
        text: String(Math.min(Notifs.list.length, 99)).padStart(2, "0")
        weight: 800
        color: Notifs.list.length > 0 ? Appearance.colors.primary : Appearance.colors.outline
        font.pixelSize: 34
    }

    Caption {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 12
        visible: Notifs.list.length === 0
        text: "Semua beres"
    }

    ListView {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: total.bottom
        anchors.topMargin: Appearance.spacing.small
        anchors.bottom: parent.bottom
        clip: true
        spacing: Appearance.spacing.normal
        interactive: contentHeight > height
        model: ScriptModel {
            values: root.latest
        }

        delegate: Column {
            required property var modelData

            width: ListView.view.width

            Caption {
                width: parent.width
                text: [parent.modelData.appName, Notifs.ago(parent.modelData)].filter(s => s).join("  ·  ")
                elide: Text.ElideRight
                font.letterSpacing: 1
            }

            StyledText {
                width: parent.width
                text: parent.modelData.summary
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        add: Transition {
            Anim {
                property: "opacity"
                from: 0
                to: 1
            }
        }
    }
}
