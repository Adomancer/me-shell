import QtQuick
import qs.components
import qs.services
import qs.utils

// Batang cava di dasar layar, transparan dan bergerak halus. Diam (dan cava berhenti) saat tidak ada lagu.
Item {
    id: root

    // Batang ramping dengan jarak lebar, ala Caelestia
    readonly property real slot: width / Cava.bars
    readonly property real gap: slot * 0.4

    opacity: Media.playing ? 1 : 0

    Behavior on opacity {
        Anim {
            duration: Appearance.anim.durations.large
        }
    }

    Row {
        x: root.gap / 2
        height: parent.height
        spacing: root.gap

        Repeater {
            model: Cava.bars

            Item {
                id: bar

                required property int index
                property real level: Cava.values[index] ?? 0

                width: root.slot - root.gap
                height: root.height

                Behavior on level {
                    Anim {
                        duration: 140
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(0, bar.level * bar.height)
                    topLeftRadius: Math.min(2, height)
                    topRightRadius: Math.min(2, height)
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Appearance.alpha(Appearance.colors.primary, 0.45)
                        }
                        GradientStop {
                            position: 1
                            color: Appearance.alpha(Appearance.colors.primary, 0.05)
                        }
                    }
                }
            }
        }
    }
}
