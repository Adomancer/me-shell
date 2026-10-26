import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.utils

// Daftar keybind (SUPER + /, ide dari cheatsheet end-4). Diambil dari `hyprctl binds -j`, jadi keybind milik
// user di user.conf ikut tampil. Keybind shell diberi nama dari Keybinds, workspace 1-9 diringkas satu baris.
Item {
    id: root

    property bool shown: false
    property real progress: shown ? 1 : 0
    // { shell: [{ keys, label }], hypr: [...] }
    property var groups: ({
            shell: [],
            hypr: []
        })
    readonly property int total: groups.shell.length + groups.hypr.length

    readonly property var dispatchers: ({
            killactive: "Tutup window",
            forcekillactive: "Paksa tutup window",
            togglefloating: "Window mengambang",
            fullscreen: "Fullscreen",
            fullscreenstate: "Fullscreen",
            pseudo: "Pseudotile",
            togglesplit: "Ganti arah split",
            pin: "Sematkan window",
            centerwindow: "Tengahkan window",
            movefocus: "Pindah fokus",
            movewindow: "Pindah window",
            swapwindow: "Tukar window",
            resizewindow: "Ubah ukuran window",
            resizeactive: "Ubah ukuran window",
            workspace: "Ke workspace",
            movetoworkspace: "Pindah window ke workspace",
            movetoworkspacesilent: "Kirim window ke workspace",
            togglespecialworkspace: "Workspace spesial",
            togglegroup: "Grup window",
            changegroupactive: "Ganti tab grup",
            exit: "Keluar dari Hyprland",
            exec: "Jalankan"
        })
    readonly property var arrows: ({
            l: "kiri",
            r: "kanan",
            u: "atas",
            d: "bawah"
        })

    function modsOf(mask: int): var {
        const out = [];
        if (mask & 64)
            out.push("SUPER");
        if (mask & 4)
            out.push("CTRL");
        if (mask & 8)
            out.push("ALT");
        if (mask & 1)
            out.push("SHIFT");
        return out;
    }

    function keyName(b: var): string {
        if (b.mouse)
            return ({
                    "mouse:272": "Klik kiri",
                    "mouse:273": "Klik kanan",
                    "mouse:274": "Klik tengah"
                })[b.key] ?? b.key;
        const k = b.key.length === 1 ? b.key.toUpperCase() : b.key;
        return ({
                slash: "/",
                period: ".",
                comma: ",",
                Return: "Enter",
                RETURN: "Enter",
                TAB: "Tab",
                Tab: "Tab",
                SPACE: "Spasi",
                space: "Spasi",
                Print: "PrtSc",
                left: "←",
                right: "→",
                up: "↑",
                down: "↓"
            })[k] ?? k;
    }

    function labelOf(b: var): string {
        if (b.has_description && b.description)
            return b.description;
        const ipc = b.arg.split("ipc call ")[1];
        if (ipc !== undefined)
            return Keybinds.binds.find(k => k.cmd === ipc)?.label ?? ipc;
        const name = dispatchers[b.dispatcher];
        // bindm: dispatcher "mouse", aksinya di arg
        if (b.dispatcher === "mouse")
            return ({
                    movewindow: "Seret window",
                    resizewindow: "Ubah ukuran window"
                })[b.arg] ?? b.arg;
        if (b.dispatcher === "exec")
            return `${name} ${b.arg.split(" ")[0].split("/").pop()}`;
        if (b.dispatcher === "movefocus" || b.dispatcher === "movewindow" || b.dispatcher === "swapwindow")
            return `${name} ${arrows[b.arg] ?? b.arg}`.trim();
        return name ?? `${b.dispatcher} ${b.arg}`.trim();
    }

    function build(list: var): void {
        const shell = [];
        const hypr = [];
        // Workspace per angka diringkas: { "mask/dispatcher": { mask, dispatcher, keys: [] } }
        const ws = {};
        for (const b of list) {
            if (b.submap || b.non_consuming || b.key.startsWith("XF86"))
                continue;
            if (["workspace", "movetoworkspace", "movetoworkspacesilent"].includes(b.dispatcher) && /^\d$/.test(b.key)) {
                const id = `${b.modmask}/${b.dispatcher}`;
                ws[id] = ws[id] ?? {
                    mask: b.modmask,
                    dispatcher: b.dispatcher,
                    keys: []
                };
                ws[id].keys.push(Number(b.key));
                continue;
            }
            const row = {
                keys: [...modsOf(b.modmask), keyName(b)],
                label: labelOf(b)
            };
            (b.arg.includes("ipc call") ? shell : hypr).push(row);
        }
        for (const id in ws) {
            const g = ws[id];
            const keys = g.keys.sort((a, b) => a - b);
            hypr.push({
                keys: [...modsOf(g.mask), keys.length > 1 ? `${keys[0]}-${keys[keys.length - 1]}` : String(keys[0])],
                label: dispatchers[g.dispatcher]
            });
        }
        groups = {
            shell,
            hypr
        };
    }

    implicitWidth: 900
    implicitHeight: 580
    // Ukuran 0 saat tertutup supaya keluar dari mask input
    width: progress > 0 ? implicitWidth : 0
    height: progress > 0 ? implicitHeight : 0
    visible: progress > 0
    opacity: progress
    scale: 0.9 + progress * 0.1

    onShownChanged: {
        if (shown) {
            binds.running = true;
            body.forceActiveFocus();
        }
    }

    Behavior on progress {
        Anim {
            duration: root.shown ? Appearance.anim.durations.expressiveDefault : Appearance.anim.durations.small
            easing.bezierCurve: root.shown ? Appearance.anim.curves.expressiveDefault : Appearance.anim.curves.emphasizedAccel
        }
    }

    Process {
        id: binds

        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.build(JSON.parse(text));
                } catch (e) {
                    console.warn("cheatsheet:", e);
                }
            }
        }
    }

    // Satu baris: tuts lalu nama aksi
    component BindRow: RowLayout {
        id: row

        required property var modelData

        width: ListView.view?.width ?? parent.width
        spacing: Appearance.spacing.normal

        Row {
            Layout.preferredWidth: 190
            spacing: 4

            Repeater {
                model: row.modelData.keys

                StyledRect {
                    required property string modelData

                    implicitWidth: Math.max(22, keyText.implicitWidth + 12)
                    implicitHeight: 22
                    radius: Appearance.radius.small
                    color: Appearance.colors.surfaceContainerHigh

                    StyledText {
                        id: keyText

                        anchors.centerIn: parent
                        text: parent.modelData
                        font.family: Appearance.font.family.mono
                        font.pixelSize: Appearance.font.size.small
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: row.modelData.label
            color: Appearance.colors.textDim
            elide: Text.ElideRight
        }
    }

    // Satu kolom: judul + daftar yang bisa digulir
    component Section: ColumnLayout {
        id: section

        property string title
        property var rows: []

        spacing: Appearance.spacing.normal

        Caption {
            text: `${section.title} · ${String(section.rows.length).padStart(2, "0")}`
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.spacing.small
            boundsBehavior: Flickable.StopAtBounds
            model: section.rows
            delegate: BindRow {}
        }
    }

    Elevation {
        anchors.fill: bg
        radius: bg.radius
        level: 3
    }

    StyledRect {
        id: bg

        anchors.fill: parent
        radius: Appearance.radius.large
        color: Appearance.colors.surface
    }

    ColumnLayout {
        id: body

        anchors.fill: parent
        anchors.margins: Appearance.padding.large + 4
        spacing: Appearance.spacing.large
        focus: true
        Keys.onEscapePressed: DrawerState.close()

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.large

            DisplayText {
                text: String(root.total).padStart(2, "0")
                weight: 800
                color: Appearance.colors.primary
                font.pixelSize: 40
            }

            StyledText {
                Layout.fillWidth: true
                text: "Keybind"
                font.pixelSize: Appearance.font.size.extraLarge
                font.weight: Font.Medium
            }

            Caption {
                text: "Esc untuk tutup"
            }
        }

        Divider {}

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.huge

            Section {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                title: "Shell"
                rows: root.groups.shell
            }

            Divider {
                vertical: true
            }

            Section {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                title: "Hyprland"
                rows: root.groups.hypr
            }
        }
    }
}
