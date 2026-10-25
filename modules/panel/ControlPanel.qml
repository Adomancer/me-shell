import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Control panel yang turun dari tengah bar.
Reveal {
    id: root

    edge: "top"
    onShownChanged: {
        if (shown)
            frame.forceActiveFocus();
    }

    RetroFrame {
        id: frame

        title: "control"
        focus: true
        Keys.onEscapePressed: DrawerState.close()

        RowLayout {
            spacing: Appearance.spacing.huge

            ColumnLayout {
                Layout.preferredWidth: 340
                Layout.alignment: Qt.AlignTop
                spacing: Appearance.spacing.large

                Header {
                    Layout.fillWidth: true
                }

                MediaCard {
                    Layout.fillWidth: true
                }

                Controls {
                    Layout.fillWidth: true
                }

                Stats {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: Appearance.border.thin
                color: Appearance.colors.outline
            }

            ColumnLayout {
                Layout.preferredWidth: 300
                Layout.alignment: Qt.AlignTop
                spacing: Appearance.spacing.large

                Calendar {
                    Layout.fillWidth: true
                }

                NotifList {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 260
                }
            }
        }
    }
}
