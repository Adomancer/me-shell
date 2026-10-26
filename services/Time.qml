pragma Singleton

import Quickshell
import QtQuick
import qs.utils

Singleton {
    id: root

    readonly property date date: clock.date
    readonly property string time: Qt.formatDateTime(clock.date, Config.clockFormat)
    readonly property string dateText: clock.date.toLocaleString(Qt.locale(), Config.dateFormat)
    // Hanya berubah sekali sehari; untuk kalender yang tidak perlu dihitung ulang tiap menit
    readonly property string today: clock.date.toDateString()
    readonly property int hour: clock.date.getHours()
    readonly property string greeting: hour < 11 ? "Selamat pagi" : hour < 15 ? "Selamat siang" : hour < 19 ? "Selamat sore" : "Selamat malam"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
