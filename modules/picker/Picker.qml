import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services
import qs.utils

// Pemilih area untuk screenshot dan rekam layar. Layar diredupkan kecuali kotak pilihan:
// hover window = pilih window itu, seret = pilih area bebas, klik di desktop = seluruh layar.
// Enter = pakai pilihan sekarang, Esc = batal.
Scope {
    Variants {
        model: Screenshot.pickerOpen ? Quickshell.screens : []

        PanelWindow {
            id: win

            required property ShellScreen modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            readonly property bool record: Screenshot.pickerMode === "record"

            // Kotak pilihan (koordinat lokal layar ini)
            property real selX: 0
            property real selY: 0
            property real selW: width
            property real selH: height
            property bool dragging: false
            property point dragStart

            // Window di workspace aktif monitor ini, yang mengambang didahulukan karena ada di atas
            function windows(): var {
                const ws = monitor?.activeWorkspace?.id;
                return Hyprland.toplevels.values.map(t => t.lastIpcObject).filter(o => o?.at && o.workspace?.id === ws && !o.hidden).sort((a, b) => b.floating - a.floating);
            }

            function snapTo(px: real, py: real): void {
                const gx = px + (monitor?.x ?? 0);
                const gy = py + (monitor?.y ?? 0);
                const w = windows().find(o => gx >= o.at[0] && gx < o.at[0] + o.size[0] && gy >= o.at[1] && gy < o.at[1] + o.size[1]);
                if (w) {
                    selX = w.at[0] - (monitor?.x ?? 0);
                    selY = w.at[1] - (monitor?.y ?? 0);
                    selW = w.size[0];
                    selH = w.size[1];
                } else {
                    selX = 0;
                    selY = 0;
                    selW = width;
                    selH = height;
                }
            }

            function finish(): void {
                if (selW < 4 || selH < 4)
                    return;
                const x = selX + (monitor?.x ?? 0);
                const y = selY + (monitor?.y ?? 0);
                const w = selW;
                const h = selH;
                const rec = record;
                Screenshot.pickerOpen = false;
                if (rec)
                    Recorder.region(x, y, w, h);
                else
                    Screenshot.region(x, y, w, h);
            }

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "me-shell-picker"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: Hyprland.refreshToplevels()

            Behavior on selX {
                enabled: !win.dragging

                Anim {
                    duration: Appearance.anim.durations.expressiveFast
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
            }
            Behavior on selY {
                enabled: !win.dragging

                Anim {
                    duration: Appearance.anim.durations.expressiveFast
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
            }
            Behavior on selW {
                enabled: !win.dragging

                Anim {
                    duration: Appearance.anim.durations.expressiveFast
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
            }
            Behavior on selH {
                enabled: !win.dragging

                Anim {
                    duration: Appearance.anim.durations.expressiveFast
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                }
            }

            // Lapisan redup dengan lubang di kotak pilihan; muncul memudar
            Shape {
                id: dim

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                opacity: 0

                Component.onCompleted: opacity = 1

                Behavior on opacity {
                    Anim {
                        duration: Appearance.anim.durations.small
                    }
                }

                ShapePath {
                    strokeWidth: -1
                    fillColor: Appearance.alpha(Appearance.colors.scrim, 0.5)
                    fillRule: ShapePath.OddEvenFill

                    PathRectangle {
                        x: 0
                        y: 0
                        width: win.width
                        height: win.height
                    }
                    PathRectangle {
                        x: win.selX
                        y: win.selY
                        width: win.selW
                        height: win.selH
                        radius: Appearance.radius.small
                    }
                }
            }

            Rectangle {
                x: win.selX
                y: win.selY
                width: win.selW
                height: win.selH
                radius: Appearance.radius.small
                color: "transparent"
                border.width: 2
                border.color: win.record ? Appearance.colors.error : Appearance.colors.primary
            }

            // Ukuran pilihan, di bawah kotak (atau di dalamnya kalau mepet bawah layar)
            StyledRect {
                x: Math.max(8, Math.min(win.width - width - 8, win.selX + (win.selW - width) / 2))
                y: win.selY + win.selH + height + 16 < win.height ? win.selY + win.selH + 8 : win.selY + win.selH - height - 8
                implicitWidth: sizeText.implicitWidth + Appearance.padding.normal * 2
                implicitHeight: 28
                radius: Appearance.radius.small
                color: Appearance.colors.surfaceContainerHigh

                StyledText {
                    id: sizeText

                    anchors.centerIn: parent
                    text: `${Math.round(win.selW)} × ${Math.round(win.selH)}`
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
                }
            }

            // Petunjuk di atas tengah
            StyledRect {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Config.barHeight + Appearance.spacing.huge
                implicitWidth: hint.implicitWidth + Appearance.padding.large * 2
                implicitHeight: 44
                radius: Appearance.radius.small
                color: Appearance.colors.surface

                Row {
                    id: hint

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.record ? "screen_record" : "screenshot_region"
                        fill: 1
                        color: win.record ? Appearance.colors.error : Appearance.colors.primary
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.record ? "Rekam layar" : "Tangkap layar"
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Klik window · seret area · Enter seluruh pilihan · Esc batal"
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor
                focus: true

                Keys.onEscapePressed: Screenshot.pickerOpen = false
                Keys.onReturnPressed: win.finish()
                Keys.onEnterPressed: win.finish()

                onPositionChanged: mouse => {
                    if (pressed) {
                        if (!win.dragging && Math.hypot(mouse.x - win.dragStart.x, mouse.y - win.dragStart.y) > 4)
                            win.dragging = true;
                        if (win.dragging) {
                            win.selX = Math.min(win.dragStart.x, mouse.x);
                            win.selY = Math.min(win.dragStart.y, mouse.y);
                            win.selW = Math.abs(mouse.x - win.dragStart.x);
                            win.selH = Math.abs(mouse.y - win.dragStart.y);
                        }
                    } else {
                        win.snapTo(mouse.x, mouse.y);
                    }
                }
                onPressed: mouse => win.dragStart = Qt.point(mouse.x, mouse.y)
                onReleased: win.finish()
            }
        }
    }
}
