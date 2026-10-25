import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.utils

StyledRect {
    id: root

    property var notif
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string icon: notif?.image || (notif?.appIcon ? Quickshell.iconPath(notif.appIcon, true) : "")

    implicitHeight: layout.implicitHeight + Appearance.spacing.normal * 2
    color: Appearance.colors.surface
    border.width: Appearance.border.normal
    border.color: critical ? Appearance.colors.error : Appearance.colors.outline

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Appearance.spacing.normal
        spacing: Appearance.spacing.normal

        IconImage {
            Layout.alignment: Qt.AlignTop
            visible: root.icon !== ""
            implicitSize: 32
            source: root.icon
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: (root.notif?.appName ?? "").toUpperCase()
                    color: root.critical ? Appearance.colors.error : Appearance.colors.textDim
                    font.pixelSize: Appearance.font.size.small
                    font.bold: true
                    elide: Text.ElideRight
                }

                StyledText {
                    text: "x"
                    color: closeArea.containsMouse ? Appearance.colors.primary : Appearance.colors.textDim
                    font.bold: true

                    MouseArea {
                        id: closeArea

                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notif?.dismiss()
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notif?.summary ?? ""
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif?.body ?? ""
                textFormat: Text.StyledText
                color: Appearance.colors.textDim
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small
                visible: (root.notif?.actions ?? []).length > 0
                spacing: Appearance.spacing.small

                Repeater {
                    model: root.notif?.actions ?? []

                    RetroButton {
                        required property var modelData

                        text: modelData.text
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
