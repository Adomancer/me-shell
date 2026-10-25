import QtQuick
import qs.components

// Toggle [x] ON / [ ] OFF
RetroButton {
    property bool checked: false

    signal toggled(bool value)

    text: checked ? "[x] ON" : "[ ] OFF"
    active: checked
    onClicked: toggled(!checked)
}
