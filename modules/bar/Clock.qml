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

    // Kedip tanpa animasi: satu frame per detik, bukan belasan
    Timer {
        interval: 1000
        repeat: true
        running: !Session.locked
        onTriggered: root.tick = !root.tick
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Repeater {
                model: root.parts

                Row {
                    id: part

                    required property string modelData
                    required property int index

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    // Titik dua: dua titik bulat, lebih jelas dari glyph Doto di ukuran kecil
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: part.index > 0
                        spacing: 5
                        opacity: root.tick ? 1 : 0.35

                        Repeater {
                            model: 2

                            Rectangle {
                                width: 3
                                height: 3
                                radius: 1.5
                                color: Appearance.colors.primary
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
