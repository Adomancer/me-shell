import QtQuick
import QtQuick.Layouts
import qs.components
import qs.utils

// Satu baris daftar di popout (jaringan, perangkat, output audio). Tanpa latar; baris aktif ditandai
// batang aksen di kiri dan teks aksen, hover = fill tipis.
StyledRect {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    // Ikon kecil di kanan, misalnya gembok jaringan
    property string trailing: ""
    property bool active: false
    property bool busy: false
    default property alias extra: slot.data

    readonly property color ink: active ? Appearance.colors.primary : Appearance.colors.text

    signal clicked

    Layout.fillWidth: true
    implicitHeight: Math.max(44, texts.implicitHeight + Appearance.padding.small * 2)
    radius: Appearance.radius.normal

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: root.active ? parent.height * 0.5 : 0
        radius: 1.5
        color: Appearance.colors.primary

        Behavior on height {
            Anim {
                duration: Appearance.anim.durations.expressiveFast
                easing.bezierCurve: Appearance.anim.curves.expressiveFast
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            fill: root.active ? 1 : 0
            color: root.active ? root.ink : Appearance.colors.textDim
        }

        ColumnLayout {
            id: texts

            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: root.ink
                font.weight: root.active ? Font.Medium : Font.Normal
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                color: root.active ? root.ink : Appearance.colors.textDim
                opacity: root.active ? 0.8 : 1
                font.pixelSize: Appearance.font.size.small
                elide: Text.ElideRight
            }
        }

        Item {
            id: slot

            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
            visible: children.length > 0
        }

        // Putaran kecil selama proses (menyambung dsb.)
        MaterialIcon {
            visible: root.busy
            text: "progress_activity"
            color: root.ink

            RotationAnimator on rotation {
                running: root.busy
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
        }

        MaterialIcon {
            visible: root.trailing !== "" && !root.busy
            text: root.trailing
            font.pixelSize: Appearance.font.size.larger
            color: root.active ? root.ink : Appearance.colors.textDim
        }
    }

    StateLayer {
        color: root.ink
        onClicked: root.clicked()
    }
}
