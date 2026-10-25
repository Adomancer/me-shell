import QtQuick
import qs.utils

// "Jendela" retro: border tegas, title bar bergaris ala Mac klasik, bayangan keras.
Item {
    id: root

    property string title: ""
    property color background: Appearance.colors.surface
    property color borderColor: Appearance.colors.outline
    property bool shadow: true
    default property alias content: body.data

    readonly property int pad: Appearance.spacing.large
    readonly property int bw: Appearance.border.normal
    readonly property int so: shadow ? Appearance.shadowOffset.normal : 0

    implicitWidth: Math.max(titleText.implicitWidth + pad * 4, body.width + pad * 2) + bw * 2 + so
    implicitHeight: titleBar.height + body.height + pad * 2 + bw * 2 + so

    Rectangle {
        visible: root.shadow
        x: root.so
        y: root.so
        width: frame.width
        height: frame.height
        radius: frame.radius
        color: Appearance.colors.shadow
        opacity: 0.6
    }

    Rectangle {
        id: frame

        width: root.width - root.so
        height: root.height - root.so
        radius: Appearance.radius.normal
        color: root.background
        border.width: root.bw
        border.color: root.borderColor

        Item {
            id: titleBar

            visible: root.title !== ""
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.bw
            height: visible ? 24 : 0

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: root.pad / 2
                anchors.rightMargin: root.pad / 2
                spacing: 2

                Repeater {
                    model: 4

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Appearance.colors.outline
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: titleText.implicitWidth + root.pad
                height: parent.height
                color: root.background

                StyledText {
                    id: titleText

                    anchors.centerIn: parent
                    text: root.title.toUpperCase()
                    color: Appearance.colors.primary
                    font.bold: true
                    font.letterSpacing: 2
                    font.pixelSize: Appearance.font.size.small
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: root.bw
                color: root.borderColor
            }
        }

        Item {
            id: body

            x: root.bw + root.pad
            y: root.bw + titleBar.height + root.pad
            width: childrenRect.width
            height: childrenRect.height
        }
    }
}
