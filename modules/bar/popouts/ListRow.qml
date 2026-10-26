import QtQuick
import QtQuick.Layouts
import qs.components
import qs.utils

// Satu baris daftar di popout (jaringan, perangkat, output audio). Baris aktif berlatar tonal.
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

    readonly property color ink: active ? Appearance.colors.secondaryContainerText : Appearance.colors.text

    signal clicked

    Layout.fillWidth: true
    implicitHeight: Math.max(44, texts.implicitHeight + Appearance.padding.small * 2)
    radius: Appearance.radius.small
    color: active ? Appearance.colors.secondaryContainer : "transparent"

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
