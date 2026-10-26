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
                text: Audio.muted ? "--" : Math.round(Audio.volume * 100)
                weight: 800
                font.pixelSize: Appearance.font.size.large
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
                text: Math.round(Brightness.value * 100)
                weight: 800
                font.pixelSize: Appearance.font.size.large
            }
        }
    }
}
