import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Tumpukan toast dari Toaster. Toast baru meluncur masuk dari kanan, yang lama turun memberi tempat.
Item {
    id: root

    readonly property int count: list.count

    implicitWidth: 360
    implicitHeight: count > 0 ? list.contentHeight : 0

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                Toaster.hold();
        }
    }

    ListView {
        id: list

        width: parent.width
        height: contentHeight
        interactive: false
        spacing: Appearance.spacing.small
        verticalLayoutDirection: ListView.BottomToTop

        model: ScriptModel {
            values: Toaster.toasts
        }

        delegate: StyledRect {
            id: toast

            required property var modelData

            width: ListView.view.width
            implicitHeight: row.implicitHeight + Appearance.padding.normal * 2
            radius: Appearance.radius.normal
            color: Appearance.colors.surfaceContainerHigh

            RowLayout {
                id: row

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                StyledRect {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: height / 2
                    color: Appearance.colors.primaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: toast.modelData.icon
                        fill: 1
                        color: Appearance.colors.primaryContainerText
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: toast.modelData.title
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: toast.modelData.body
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                        elide: Text.ElideMiddle
                    }
                }

                // Gambar kecil, misalnya hasil screenshot
                StyledClippingRect {
                    visible: toast.modelData.image !== ""
                    implicitWidth: 72
                    implicitHeight: 44
                    radius: Appearance.radius.small

                    Image {
                        anchors.fill: parent
                        source: toast.modelData.image ? `file://${toast.modelData.image}` : ""
                        sourceSize: Qt.size(144, 88)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }

            StateLayer {
                onClicked: Toaster.dismiss(toast.modelData.id)
            }
        }

        add: Transition {
            Anim {
                property: "x"
                from: list.width
                to: 0
                duration: Appearance.anim.durations.expressiveDefault
                easing.bezierCurve: Appearance.anim.curves.expressiveDefault
            }
            Anim {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.anim.durations.small
            }
        }

        remove: Transition {
            Anim {
                property: "x"
                to: list.width
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
            Anim {
                property: "opacity"
                to: 0
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }

        displaced: Transition {
            Anim {
                property: "y"
                duration: Appearance.anim.durations.expressiveDefault
                easing.bezierCurve: Appearance.anim.curves.expressiveDefault
            }
            Anim {
                property: "x"
                to: 0
            }
            Anim {
                property: "opacity"
                to: 1
            }
        }
    }
}
