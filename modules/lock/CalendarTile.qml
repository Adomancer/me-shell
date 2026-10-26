import QtQuick
import qs.components
import qs.services
import qs.utils

// Kalender bulan ini, minggu dimulai Senin. Hari ini = lingkaran aksen.
Tile {
    id: root

    // Bergantung pada Time.today supaya hanya dihitung ulang saat hari berganti
    readonly property date now: {
        Time.today;
        return new Date();
    }
    readonly property int today: now.getDate()
    readonly property var cells: {
        const first = new Date(now.getFullYear(), now.getMonth(), 1);
        const days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < lead; i++)
            out.push(0);
        for (let d = 1; d <= days; d++)
            out.push(d);
        return out;
    }
    readonly property int weeks: Math.ceil(cells.length / 7)
    readonly property real cellW: body.width / 7
    readonly property real cellH: (body.height - header.height - Appearance.spacing.small) / (weeks + 1)

    Caption {
        id: header

        anchors.left: parent.left
        anchors.top: parent.top
        text: root.now.toLocaleString(Qt.locale(), "MMMM yyyy")
    }

    Item {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: Appearance.spacing.small
        anchors.bottom: parent.bottom

        Repeater {
            model: ["S", "S", "R", "K", "J", "S", "M"]

            StyledText {
                required property string modelData
                required property int index

                x: index * root.cellW
                width: root.cellW
                height: root.cellH
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: index >= 5 ? Appearance.colors.primary : Appearance.colors.outline
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.small - 1
            }
        }

        Repeater {
            model: root.cells

            Item {
                required property int modelData
                required property int index
                readonly property bool isToday: modelData === root.today

                x: index % 7 * root.cellW
                y: (Math.floor(index / 7) + 1) * root.cellH
                width: root.cellW
                height: root.cellH
                visible: modelData > 0

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 2
                    height: width
                    radius: width / 2
                    visible: parent.isToday
                    color: Appearance.colors.primary
                }

                StyledText {
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.isToday ? Appearance.colors.primaryText : parent.modelData < root.today ? Appearance.colors.outline : Appearance.colors.text
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                }
            }
        }
    }
}
