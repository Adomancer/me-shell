import Quickshell
import QtQuick
import qs.components
import qs.services
import qs.utils

// Jam dot-matrix besar + tanggal + 60 titik detik yang menyala bergiliran.
Tile {
    id: root

    // Waktu lockscreen mulai, untuk "terkunci sejak"
    readonly property date since: new Date()

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "lock"
            fill: 1
            font.pixelSize: Appearance.font.size.larger
            color: Appearance.colors.primary
        }

        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: `Terkunci sejak ${Qt.formatDateTime(root.since, "hh:mm")}`
        }
    }

    Caption {
        anchors.right: parent.right
        anchors.top: parent.top
        text: Time.date.toLocaleString(Qt.locale(), "dddd")
        color: Appearance.colors.text
    }

    DisplayText {
        id: time

        anchors.left: parent.left
        anchors.leftMargin: -4
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -6
        text: Qt.formatDateTime(clock.date, Config.clockFormat)
        weight: 800
        font.pixelSize: Math.round(Math.min(parent.height * 0.6, parent.width * 0.28))
    }

    Caption {
        anchors.left: parent.left
        anchors.bottom: seconds.top
        anchors.bottomMargin: Appearance.spacing.normal
        text: clock.date.toLocaleString(Qt.locale(), "d MMMM yyyy")
        color: Appearance.colors.primary
    }

    // Detik besar dan redup di samping jam
    DisplayText {
        anchors.left: time.right
        anchors.leftMargin: Appearance.spacing.huge
        anchors.baseline: time.baseline
        text: String(clock.date.getSeconds()).padStart(2, "0")
        color: Appearance.colors.outline
        weight: 800
        font.pixelSize: Math.round(time.font.pixelSize * 0.45)
    }

    // Detik: titik ke-n menyala, titik sekarang warna aksen
    Item {
        id: seconds

        readonly property int sec: clock.date.getSeconds()

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 5

        Repeater {
            model: 60

            Rectangle {
                required property int index

                x: index * (seconds.width - width) / 59
                width: 4
                height: 4
                radius: 2
                color: index === seconds.sec ? Appearance.colors.primary : index < seconds.sec ? Appearance.colors.textDim : Appearance.colors.hairline
                scale: index === seconds.sec ? 1.5 : 1

                Behavior on scale {
                    Anim {
                        duration: Appearance.anim.durations.small
                    }
                }
            }
        }
    }
}
