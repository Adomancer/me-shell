import QtQuick
import QtQuick.Shapes
import qs.utils

// Cincin progres: track redup dengan busur terisi yang bergerak halus, angka di tengah.
Item {
    id: root

    property real value: 0
    property string icon: ""
    property string label: ""
    property int size: 88
    property int thickness: 8
    property color color: Appearance.colors.primary
    property real shown: Math.max(0, Math.min(1, value))
    readonly property real r: (size - thickness) / 2

    implicitWidth: size
    implicitHeight: size

    Behavior on shown {
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Appearance.colors.secondaryContainer
            strokeWidth: root.thickness
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.r
                radiusY: root.r
                // Celah kecil di bawah, ala pengukur
                startAngle: 135
                sweepAngle: 270
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.thickness
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.r
                radiusY: root.r
                startAngle: 135
                sweepAngle: Math.max(0.1, 270 * root.shown)
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.value * 100) + "%"
            font.family: Appearance.font.family.mono
            font.pixelSize: Appearance.font.size.larger
            font.bold: true
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Appearance.colors.textDim
            font.pixelSize: Appearance.font.size.small
        }
    }
}
