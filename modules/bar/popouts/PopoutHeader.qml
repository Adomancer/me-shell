import QtQuick
import QtQuick.Layouts
import qs.components
import qs.utils

// Judul popout: ikon + teks, switch opsional di kanan.
RowLayout {
    id: root

    property string icon: ""
    property string title: ""
    property bool hasSwitch: false
    property bool checked: false
    property bool switchEnabled: true

    signal toggled(bool value)

    Layout.fillWidth: true
    Layout.bottomMargin: Appearance.spacing.small
    spacing: Appearance.spacing.normal

    MaterialIcon {
        text: root.icon
        fill: 1
        color: Appearance.colors.primary
    }

    StyledText {
        Layout.fillWidth: true
        text: root.title
        font.pixelSize: Appearance.font.size.larger
        font.weight: Font.Medium
    }

    StyledSwitch {
        visible: root.hasSwitch
        enabled: root.switchEnabled
        opacity: enabled ? 1 : 0.38
        checked: root.checked
        onToggled: v => root.toggled(v)
    }
}
