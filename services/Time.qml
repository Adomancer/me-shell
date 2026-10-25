pragma Singleton

import Quickshell
import QtQuick
import qs.utils

Singleton {
    id: root

    readonly property date date: clock.date
    readonly property string time: Qt.formatDateTime(clock.date, Config.clockFormat)
    readonly property string dateText: clock.date.toLocaleString(Qt.locale(), Config.dateFormat)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
