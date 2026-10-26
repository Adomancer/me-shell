import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Kartu notifikasi. Geser ke kanan untuk menutup. progress >= 0 menampilkan sisa waktu popup sebagai
// deretan segmen di bawah.
Item {
    id: root

    property var notif
    property color background: Appearance.colors.surfaceContainer
    // -1 = tanpa hitung mundur
    property real progress: -1
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string image: notif?.image ?? ""
    readonly property string appIcon: notif?.appIcon ? Quickshell.iconPath(notif.appIcon, true) : ""
    readonly property bool hovered: hover.hovered

    implicitHeight: card.implicitHeight

    function dismiss(): void {
        root.notif?.dismiss();
    }

    HoverHandler {
        id: hover
    }

    StyledRect {
        id: card

        width: parent.width
        implicitHeight: layout.implicitHeight + Appearance.padding.normal * 2 + (root.progress >= 0 ? 10 : 0)
        radius: Appearance.radius.normal
        color: root.background
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

            // Gambar notifikasi, ikon app, atau ikon lonceng; tanpa lingkaran berisi
            Item {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 40
                implicitHeight: 40

                StyledClippingRect {
                    anchors.fill: parent
                    visible: root.image !== ""
                    radius: Appearance.radius.normal
                    color: Appearance.colors.surfaceContainerHigh

                    Image {
                        anchors.fill: parent
                        source: root.image
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: root.image === "" && root.appIcon !== ""
                    implicitSize: 32
                    source: root.appIcon
                    asynchronous: true
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: root.image === "" && root.appIcon === ""
                    text: root.critical ? "priority_high" : "notifications"
                    font.pixelSize: 28
                    color: root.critical ? Appearance.colors.error : Appearance.colors.textDim
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    // Penanda penting: titik merah
                    Rectangle {
                        visible: root.critical
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: Appearance.colors.error
                    }

                    Caption {
                        Layout.fillWidth: true
                        text: [root.critical ? "Penting" : "", root.notif?.appName ?? ""].filter(s => s).join("  ·  ")
                        color: root.critical ? Appearance.colors.error : Appearance.colors.textDim
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: Notifs.ago(root.notif)
                        color: Appearance.colors.outline
                        font.family: Appearance.font.family.mono
                        font.pixelSize: Appearance.font.size.small
                    }

                    // Muncul saat kursor di atas kartu
                    IconButton {
                        icon: "close"
                        size: Appearance.font.size.larger
                        padding: 2
                        opacity: root.hovered ? 1 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            Anim {
                                duration: Appearance.anim.durations.small
                            }
                        }

                        onClicked: root.dismiss()
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.notif?.summary ?? ""
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

                        TextButton {
                            required property var modelData

                            text: modelData.text
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }

        // Sisa waktu popup
        SegmentBar {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Appearance.padding.normal
            anchors.bottomMargin: Appearance.padding.small + 2
            visible: root.progress >= 0
            height: 3
            segments: 40
            instant: true
            value: root.progress
            onColor: root.critical ? Appearance.colors.error : Appearance.colors.textDim
            opacity: root.hovered ? 0.4 : 1
        }
    }
}
