import QtQuick
import qs.components
import qs.services
import qs.utils

// Jam di tengah bar: angka dot-matrix dengan titik dua berkedip, tanggal sebagai label mono.
// Klik membuka dashboard; drawer terbuka ditandai strip aksen di bawahnya.
StyledRect {
    id: root

    readonly property bool active: DrawerState.active === "panel"
    readonly property bool hovered: layer.containsMouse
    // "12:06" -> ["12", "06"]; titik dua digambar sendiri supaya bisa berkedip
    readonly property var parts: Time.time.split(":")
    property bool tick: true

    implicitWidth: row.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: Config.barHeight - 10
    radius: height / 2

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.tick = !root.tick
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        Row {
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: root.parts

                Row {
                    id: part

                    required property string modelData
                    required property int index

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: part.index > 0
                        text: ":"
                        color: Appearance.colors.primary
                        font.family: Appearance.font.family.display
                        font.pixelSize: 24
                        opacity: root.tick ? 1 : 0.15

                        Behavior on opacity {
                            Anim {
                                duration: Appearance.anim.durations.small
                            }
                        }
                    }

                    DisplayText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: part.modelData
                        weight: 900
                        font.pixelSize: 24
                    }
                }
            }
        }

        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.dateText
        }
    }

    StateLayer {
        id: layer

        onClicked: DrawerState.togglePanel("dash")
    }

    ActiveDot {
        active: root.active
    }
}
