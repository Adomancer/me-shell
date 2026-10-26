import QtQuick
import qs.components
import qs.services
import qs.utils

// Timer fokus/stopwatch yang sedang jalan, tanpa kotak: ikon + sisa waktu mono. Klik = buka tab Fokus.
StyledRect {
    id: root

    implicitWidth: row.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: Config.barHeight - 10
    radius: height / 2

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: Focus.mode === "break" ? "coffee" : Focus.mode === "stopwatch" ? "avg_pace" : "timer"
            fill: Focus.running ? 1 : 0
            color: Focus.running ? Appearance.colors.primary : Appearance.colors.textDim
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Focus.text
            color: Focus.running ? Appearance.colors.text : Appearance.colors.textDim
            font.family: Appearance.font.family.mono
            font.pixelSize: Appearance.font.size.smaller
        }
    }

    StateLayer {
        onClicked: DrawerState.togglePanel("focus")
    }
}
