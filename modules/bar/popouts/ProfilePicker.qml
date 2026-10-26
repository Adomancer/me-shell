import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Tiga tombol power profile; yang aktif melebar dan berwarna aksen.
ColumnLayout {
    id: root

    readonly property var profiles: [
        {
            value: PowerProfile.PowerSaver,
            icon: "energy_savings_leaf",
            label: "Hemat"
        },
        {
            value: PowerProfile.Balanced,
            icon: "balance",
            label: "Seimbang"
        },
        {
            value: PowerProfile.Performance,
            icon: "bolt",
            label: "Performa"
        }
    ]

    spacing: Appearance.spacing.small

    Caption {
        text: "Power profile"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: root.profiles

            StyledRect {
                id: btn

                required property var modelData
                readonly property bool isActive: Battery.profile === modelData.value
                readonly property bool usable: modelData.value !== PowerProfile.Performance || Battery.hasPerformance
                readonly property color ink: isActive ? Appearance.colors.primaryText : Appearance.colors.text

                Layout.fillWidth: true
                Layout.preferredWidth: isActive ? 140 : 90
                implicitHeight: 40
                radius: height / 2
                color: isActive ? Appearance.colors.primary : "transparent"
                border.width: isActive ? 0 : 1
                border.color: Appearance.colors.hairline
                opacity: usable ? 1 : 0.38

                Behavior on Layout.preferredWidth {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: btn.modelData.icon
                        fill: btn.isActive ? 1 : 0
                        color: btn.ink
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: btn.isActive
                        text: btn.modelData.label
                        color: btn.ink
                        font.weight: Font.Medium
                    }
                }

                StateLayer {
                    disabled: !btn.usable
                    color: btn.ink
                    onClicked: Battery.setProfile(btn.modelData.value)
                }
            }
        }
    }
}
