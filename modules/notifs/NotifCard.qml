import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Kartu notifikasi. Geser ke kanan untuk menutup.
Item {
    id: root

    property var notif
    property color background: Appearance.colors.surfaceContainer
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string image: notif?.image ?? ""
    readonly property string appIcon: notif?.appIcon ? Quickshell.iconPath(notif.appIcon, true) : ""
    readonly property color ink: critical ? Appearance.colors.errorContainerText : Appearance.colors.text

    implicitHeight: card.implicitHeight

    function dismiss(): void {
        root.notif?.dismiss();
    }

    StyledRect {
        id: card

        width: parent.width
        implicitHeight: layout.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.radius.normal
        color: root.critical ? Appearance.colors.errorContainer : root.background
        opacity: 1 - Math.min(1, Math.abs(x) / width) * 0.8

        // Kembali ke tempat dengan pegas kalau geseran kurang jauh
        Behavior on x {
            enabled: !swipe.active

            Anim {
                duration: Appearance.anim.durations.expressiveDefault
                easing.bezierCurve: Appearance.anim.curves.expressiveDefault
            }
        }

        DragHandler {
            id: swipe

            xAxis.minimum: 0
            yAxis.enabled: false
            onActiveChanged: {
                if (active)
                    return;
                if (card.x > card.width * 0.35)
                    root.dismiss();
                else
                    card.x = 0;
            }
        }

        RowLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.large

            // Gambar notifikasi, ikon app, atau ikon lonceng
            StyledClippingRect {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 40
                implicitHeight: 40
                radius: root.image ? Appearance.radius.small : height / 2
                color: root.critical ? Appearance.colors.error : Appearance.colors.primaryContainer

                Image {
                    anchors.fill: parent
                    visible: root.image !== ""
                    source: root.image
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: root.image === "" && root.appIcon !== ""
                    implicitSize: 26
                    source: root.appIcon
                    asynchronous: true
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: root.image === "" && root.appIcon === ""
                    text: root.critical ? "priority_high" : "notifications"
                    fill: 1
                    color: root.critical ? Appearance.colors.errorText : Appearance.colors.primaryContainerText
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    Caption {
                        Layout.fillWidth: true
                        text: [root.notif?.appName ?? "", Notifs.ago(root.notif)].filter(s => s).join("  ·  ")
                        color: root.critical ? root.ink : Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                        elide: Text.ElideRight
                    }

                    IconButton {
                        icon: "close"
                        size: Appearance.font.size.larger
                        padding: 2
                        onClicked: root.dismiss()
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.notif?.summary ?? ""
                    color: root.ink
                    font.pixelSize: Appearance.font.size.larger
                    font.weight: Font.Medium
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notif?.body ?? ""
                    textFormat: Text.StyledText
                    color: root.critical ? root.ink : Appearance.colors.textDim
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

                        TextButton {
                            required property var modelData

                            text: modelData.text
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
