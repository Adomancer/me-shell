import QtQuick
import qs.components
import qs.services
import qs.utils

// OSD volume + brightness yang menempel di tepi kanan. Bisa langsung digeser.
Item {
    id: root

    implicitWidth: row.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: row.implicitHeight + Appearance.padding.normal * 2

    HoverHandler {
        onHoveredChanged: hovered ? OsdState.hold() : OsdState.release()
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        Column {
            spacing: Appearance.spacing.small

            VSlider {
                value: Audio.muted ? 0 : Audio.volume
                icon: Audio.muted ? "volume_off" : Audio.volume < 0.5 ? "volume_down" : "volume_up"
                onMoved: v => Audio.setVolume(v)
            }

            DisplayText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Audio.muted ? "--" : String(Math.round(Audio.volume * 100)).padStart(2, "0")
                weight: 800
                color: Audio.muted ? Appearance.colors.outline : Appearance.colors.text
                font.pixelSize: 24
            }

            Caption {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Audio.muted ? "Bisu" : "Vol"
                color: Audio.muted ? Appearance.colors.error : Appearance.colors.textDim
            }
        }

        Column {
            visible: Brightness.available
            spacing: Appearance.spacing.small

            VSlider {
                value: Brightness.value
                icon: "light_mode"
                onMoved: v => Brightness.set(v)
            }

            DisplayText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: String(Math.round(Brightness.value * 100)).padStart(2, "0")
                weight: 800
                font.pixelSize: 24
            }

            Caption {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "LCD"
            }
        }
    }
}
