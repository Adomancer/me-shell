import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    property int month: new Date().getMonth()
    property int year: new Date().getFullYear()

    function shift(delta: int): void {
        const m = month + delta;
        year += Math.floor(m / 12);
        month = ((m % 12) + 12) % 12;
    }

    function reset(): void {
        const d = new Date();
        month = d.getMonth();
        year = d.getFullYear();
    }

    spacing: Appearance.spacing.small

    Connections {
        target: DrawerState

        function onActiveChanged(): void {
            if (DrawerState.active === "panel")
                root.reset();
        }
    }

    RowLayout {
        Layout.fillWidth: true

        RetroButton {
            text: "<"
            onClicked: root.shift(-1)
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: `${Qt.locale().standaloneMonthName(root.month, Locale.LongFormat)} ${root.year}`.toUpperCase()
            font.bold: true
        }

        RetroButton {
            text: ">"
            onClicked: root.shift(1)
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 2
        rowSpacing: 2

        // Senin duluan
        Repeater {
            model: 7

            StyledText {
                required property int index

                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((index + 1) % 7, Locale.NarrowFormat)
                color: Appearance.colors.textDim
                font.pixelSize: Appearance.font.size.small
                font.bold: true
            }
        }

        Repeater {
            model: 42

            StyledRect {
                id: cell

                required property int index
                readonly property date day: {
                    const first = new Date(root.year, root.month, 1);
                    const offset = (first.getDay() + 6) % 7;
                    return new Date(root.year, root.month, 1 - offset + index);
                }
                readonly property bool inMonth: day.getMonth() === root.month
                readonly property bool isToday: day.toDateString() === Time.date.toDateString()

                Layout.fillWidth: true
                implicitHeight: 24
                color: isToday ? Appearance.colors.primary : "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: cell.day.getDate()
                    color: cell.isToday ? Appearance.colors.onPrimary : cell.inMonth ? Appearance.colors.text : Appearance.colors.textDim
                    opacity: cell.inMonth ? 1 : 0.5
                    font.bold: cell.isToday
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
    }
}
