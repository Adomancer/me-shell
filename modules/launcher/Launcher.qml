import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.components
import qs.services
import qs.utils
import "../../utils/Calc.js" as Calc
import "../../utils/Fuzzy.js" as Fuzzy

// Launcher dari tepi bawah. Atas ke bawah: tab mode + penghitung, kolom cari, isi, petunjuk tombol.
// Mode lewat prefix (atau Tab / klik tab):
//   (kosong) aplikasi   / aksi shell   ; clipboard   . emoji   : wallpaper   = kalkulator   > perintah shell
// Isi tampil sebagai daftar bernomor, grid (aplikasi favorit, emoji, wallpaper), atau angka besar (kalkulator).
Item {
    id: root

    property bool shown: false

    readonly property var modes: [
        {
            key: "apps",
            prefix: "",
            label: "Apps",
            icon: "search",
            hint: "Cari aplikasi"
        },
        {
            key: "action",
            prefix: "/",
            label: "Aksi",
            icon: "bolt",
            hint: "Cari aksi shell"
        },
        {
            key: "clip",
            prefix: ";",
            label: "Clip",
            icon: "content_paste",
            hint: "Cari di clipboard"
        },
        {
            key: "emoji",
            prefix: ".",
            label: "Emoji",
            icon: "mood",
            hint: "Cari emoji (inggris)"
        },
        {
            key: "wall",
            prefix: ":",
            label: "Wall",
            icon: "wallpaper",
            hint: "Cari wallpaper"
        },
        {
            key: "calc",
            prefix: "=",
            label: "Hitung",
            icon: "calculate",
            hint: "Tulis hitungan, misalnya 12*(3+4)"
        },
        {
            key: "run",
            prefix: ">",
            label: "Run",
            icon: "terminal",
            hint: "Perintah shell"
        }
    ]

    readonly property string query: input.text
    readonly property var modeInfo: modes.find(m => m.prefix !== "" && query.charAt(0) === m.prefix) ?? modes[0]
    readonly property string mode: modeInfo.key
    readonly property string term: mode === "apps" ? query.trim() : query.slice(1).trim()
    // "list", "grid", atau "calc"
    readonly property string view: mode === "calc" ? "calc" : mode === "wall" || mode === "emoji" || (mode === "apps" && term === "") ? "grid" : "list"
    readonly property bool showEmpty: results.length === 0 && view !== "calc" && (query !== "" || mode === "clip")

    readonly property int pad: Appearance.padding.large
    readonly property int rowHeight: 52
    readonly property int maxRows: Config.launcherMaxResults
    readonly property int gridCols: mode === "wall" ? 4 : mode === "emoji" ? 10 : 6
    readonly property int gridRows: mode === "emoji" ? 4 : 2
    readonly property real cellW: Math.floor((width - pad * 2) / gridCols)
    readonly property real cellH: mode === "wall" ? Math.round(cellW * 0.7) : mode === "emoji" ? cellW : 96

    // Aksi untuk mode "/". run dipanggil setelah launcher tertutup; keep = launcher tetap terbuka.
    readonly property var actions: [
        {
            icon: "screenshot_region",
            title: "Screenshot area",
            subtitle: "Klik window atau seret area",
            run: () => Screenshot.openPicker("screenshot")
        },
        {
            icon: "screenshot_monitor",
            title: "Screenshot layar penuh",
            run: () => Screenshot.full()
        },
        {
            icon: "screen_record",
            title: Recorder.recording ? "Hentikan rekaman" : "Rekam layar",
            run: () => Recorder.recording ? Recorder.stop() : Screenshot.openPicker("record")
        },
        {
            icon: "colorize",
            title: "Ambil warna dari layar",
            run: () => Screenshot.pickColor()
        },
        {
            icon: "coffee",
            title: Idle.inhibited ? "Matikan kafein" : "Kafein (tahan layar menyala)",
            run: () => Idle.toggleInhibit()
        },
        {
            icon: "sports_esports",
            title: GameMode.enabled ? "Matikan mode game" : "Mode game",
            run: () => GameMode.toggle()
        },
        {
            icon: "nightlight",
            title: NightLight.enabled ? "Matikan lampu malam" : "Lampu malam",
            run: () => NightLight.toggle()
        },
        {
            icon: "do_not_disturb_on",
            title: Notifs.dnd ? "Matikan jangan ganggu" : "Jangan ganggu",
            run: () => Notifs.toggleDnd()
        },
        {
            icon: Config.colorMode === "dark" ? "light_mode" : "dark_mode",
            title: Config.colorMode === "dark" ? "Tema terang" : "Tema gelap",
            run: () => {
                Config.set("colorMode", Config.colorMode === "dark" ? "light" : "dark");
                if (Wallpaper.current)
                    Wallpaper.set(Wallpaper.current);
            }
        },
        {
            icon: "shuffle",
            title: "Wallpaper acak",
            run: () => {
                if (walls.count > 0)
                    Wallpaper.set(walls.get(Math.floor(Math.random() * walls.count), "filePath"));
            }
        },
        {
            icon: "wallpaper",
            title: "Pilih wallpaper",
            keep: true,
            run: () => root.setQuery(":")
        },
        {
            icon: "content_paste",
            title: "Riwayat clipboard",
            keep: true,
            run: () => root.setQuery(";")
        },
        {
            icon: "grid_view",
            title: "Overview workspace",
            run: () => DrawerState.open("overview")
        },
        {
            icon: "widgets",
            title: "Utilitas",
            run: () => DrawerState.open("utilities")
        },
        {
            icon: "settings",
            title: "Pengaturan",
            run: () => DrawerState.open("settings")
        },
        {
            icon: "keyboard",
            title: "Daftar keybind",
            run: () => DrawerState.open("cheatsheet")
        },
        {
            icon: "system_update_alt",
            title: Updates.count > 0 ? `Perbarui sistem (${Updates.count} paket)` : "Perbarui sistem",
            subtitle: "Buka terminal dan jalankan upgrade",
            run: () => Updates.upgrade()
        },
        {
            icon: "lock",
            title: "Kunci layar",
            run: () => Session.lock()
        },
        {
            icon: "bedtime",
            title: "Tidur",
            run: () => Session.suspend()
        },
        {
            icon: "restart_alt",
            title: "Restart",
            run: () => Session.reboot()
        },
        {
            icon: "power_settings_new",
            title: "Matikan",
            run: () => Session.poweroff()
        },
        {
            icon: "logout",
            title: "Keluar dari Hyprland",
            run: () => Session.logout()
        }
    ]

    // Tidak dihitung selama tertutup (aksi dan daftar aplikasi bisa berubah kapan saja)
    readonly property var results: {
        if (!shown && !visible)
            return [];
        switch (mode) {
        case "calc":
            {
                const r = Calc.evaluate(term);
                return r === null ? [] : [
                    {
                        kind: "calc",
                        icon: "calculate",
                        title: String(r),
                        subtitle: "Enter untuk menyalin"
                    }
                ];
            }
        case "run":
            return term ? [
                {
                    kind: "run",
                    icon: "terminal",
                    title: term,
                    subtitle: "Jalankan di shell"
                }
            ] : [];
        case "action":
            {
                // sort V4 tidak stabil, jadi tanpa kata kunci urutan asli dipakai apa adanya
                const scored = actions.map(a => ({
                            a,
                            s: Fuzzy.score(term, a.title)
                        })).filter(r => r.s > 0);
                return (term ? scored.sort((x, y) => y.s - x.s) : scored).slice(0, 40).map(r => Object.assign({
                        kind: "action",
                        subtitle: r.a.subtitle ?? ""
                    }, r.a));
            }
        case "clip":
            {
                const t = term.toLowerCase();
                return Clipboard.entries.filter(e => !t || e.text.toLowerCase().includes(t)).slice(0, 50).map(e => {
                    const img = e.text.match(/binary data .*? (\w+) (\d+x\d+)/);
                    return {
                        kind: "clip",
                        icon: e.image ? "image" : "notes",
                        title: img ? `Gambar ${img[1].toUpperCase()} ${img[2].replace("x", " × ")}` : e.text.replace(/\s+/g, " ").trim(),
                        subtitle: e.image ? "Enter untuk menyalin lagi" : "",
                        line: e.line
                    };
                });
            }
        case "emoji":
            {
                const words = term.toLowerCase().split(/\s+/).filter(w => w);
                return Emojis.list.filter(e => words.every(w => e[1].includes(w))).slice(0, 200).map(e => ({
                            kind: "emoji",
                            glyph: e[0],
                            title: e[1]
                        }));
            }
        case "wall":
            {
                const out = [];
                const t = term.toLowerCase();
                for (let i = 0; i < walls.count; i++) {
                    const name = walls.get(i, "fileName");
                    if (!t || name.toLowerCase().includes(t))
                        out.push({
                            kind: "wall",
                            title: name,
                            path: walls.get(i, "filePath")
                        });
                }
                return out;
            }
        default:
            {
                const apps = Apps.search(term, term ? maxRows : gridCols * gridRows).map(a => ({
                            kind: "app",
                            title: a.name,
                            subtitle: a.comment || a.genericName || "",
                            icon: a.icon,
                            entry: a
                        }));
                // Hitungan langsung di mode aplikasi kalau yang diketik jelas rumus ("12*4", bukan "12")
                const r = /[-+*/%^]/.test(term) ? Calc.evaluate(term) : null;
                return r === null ? apps : [
                    {
                        kind: "calc",
                        icon: "calculate",
                        title: String(r),
                        subtitle: `${term} =`
                    },
                    ...apps
                ];
            }
        }
    }

    readonly property var current: results[currentIndex()] ?? null
    readonly property string sectionTitle: ({
            apps: term ? "Hasil" : "Sering dipakai",
            action: "Aksi shell",
            clip: "Riwayat clipboard",
            emoji: "Emoji",
            wall: "Wallpaper",
            calc: "Kalkulator",
            run: "Perintah"
        })[mode]

    function currentIndex(): int {
        return view === "grid" ? grid.currentIndex : view === "list" ? list.currentIndex : 0;
    }

    function setQuery(q: string): void {
        input.text = q;
        input.cursorPosition = q.length;
    }

    // Pindah mode dengan Tab / klik tab; kata kunci yang sudah diketik dibawa
    function setMode(i: int): void {
        const m = modes[(i + modes.length) % modes.length];
        setQuery(m.prefix + term);
        input.forceActiveFocus();
    }

    function cycleMode(d: int): void {
        setMode(modes.indexOf(modeInfo) + d);
    }

    function activate(i: int): void {
        const r = results[i];
        if (!r)
            return;
        if (r.kind === "action") {
            if (r.keep) {
                r.run();
                return;
            }
            DrawerState.close();
            r.run();
            return;
        }
        switch (r.kind) {
        case "app":
            Apps.launch(r.entry);
            break;
        case "calc":
            Quickshell.execDetached(["wl-copy", r.title]);
            Toaster.show("calculate", "Hasil disalin", r.title, "");
            break;
        case "run":
            Quickshell.execDetached(["sh", "-c", r.title]);
            break;
        case "clip":
            Clipboard.copy(r.line);
            break;
        case "emoji":
            Quickshell.execDetached(["wl-copy", r.glyph]);
            Toaster.show("mood", "Emoji disalin", `${r.glyph}  ${r.title}`, "");
            break;
        case "wall":
            Wallpaper.set(r.path);
            break;
        }
        DrawerState.close();
    }

    implicitWidth: mode === "wall" ? 920 : 700
    implicitHeight: col.implicitHeight + pad * 2

    onResultsChanged: {
        list.currentIndex = 0;
        grid.currentIndex = 0;
        // Wallpaper aktif jadi pilihan awal (setelah model grid ikut berganti)
        if (mode === "wall")
            Qt.callLater(() => grid.currentIndex = Math.max(0, results.findIndex(r => r.path === Wallpaper.current)));
    }
    onModeChanged: {
        if (mode === "clip")
            Clipboard.refresh();
    }
    onShownChanged: {
        if (shown) {
            setQuery(DrawerState.launcherQuery);
            DrawerState.launcherQuery = "";
            hoverGuard.last = Qt.point(-1, -1);
            input.forceActiveFocus();
        }
    }

    // Petunjuk tombol di kaki: tuts kecil + label
    component Hint: Row {
        id: hint

        property string key
        property string label

        spacing: Appearance.spacing.small

        StyledRect {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.max(20, keyText.implicitWidth + 10)
            implicitHeight: 20
            radius: Appearance.radius.small
            color: Appearance.colors.surfaceContainerHigh

            StyledText {
                id: keyText

                anchors.centerIn: parent
                text: hint.key
                color: Appearance.colors.text
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.small - 1
            }
        }

        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: hint.label
            font.letterSpacing: 1
        }
    }

    // Pilih item di bawah kursor hanya kalau mouse benar-benar bergerak, bukan saat isi bergeser
    QtObject {
        id: hoverGuard

        // Koordinat window; x < 0 = belum tercatat sejak dibuka
        property point last: Qt.point(-1, -1)

        function moved(item: Item, x: real, y: real): bool {
            const p = item.mapToItem(null, x, y);
            const m = last.x >= 0 && (p.x !== last.x || p.y !== last.y);
            last = p;
            return m;
        }
    }

    FolderListModel {
        id: walls

        folder: `file://${Config.wallpaperDir}`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    Column {
        id: col

        x: root.pad
        y: root.pad
        width: root.width - root.pad * 2
        spacing: Appearance.spacing.normal

        // Tab mode + penghitung hasil dot-matrix
        Item {
            width: parent.width
            height: 34

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacing.huge

                Repeater {
                    model: root.modes

                    Item {
                        id: tab

                        required property var modelData
                        required property int index
                        readonly property bool active: root.mode === modelData.key

                        implicitWidth: tabLabel.implicitWidth
                        implicitHeight: 34

                        Caption {
                            id: tabLabel

                            anchors.verticalCenter: parent.verticalCenter
                            text: tab.modelData.label
                            color: tab.active ? Appearance.colors.primary : tabMouse.containsMouse ? Appearance.colors.text : Appearance.colors.textDim
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: tabLabel.bottom
                            anchors.topMargin: 4
                            width: tab.active ? 14 : 4
                            height: 3
                            radius: 1.5
                            color: Appearance.colors.primary
                            opacity: tab.active ? 1 : 0

                            Behavior on width {
                                Anim {
                                    duration: Appearance.anim.durations.expressiveFast
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFast
                                }
                            }
                            Behavior on opacity {
                                Anim {
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }

                        MouseArea {
                            id: tabMouse

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setMode(tab.index)
                        }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacing.small

                Caption {
                    anchors.baseline: counter.baseline
                    text: root.view === "calc" ? "Hasil" : "Item"
                }

                DisplayText {
                    id: counter

                    text: root.view === "calc" ? (root.results.length > 0 ? "01" : "00") : String(Math.min(root.results.length, 99)).padStart(2, "0")
                    weight: 800
                    font.pixelSize: 26
                    color: root.results.length > 0 ? Appearance.colors.text : Appearance.colors.outline
                }
            }
        }

        // Kolom cari tanpa kotak: ikon mode, teks besar, garis bawah
        Item {
            width: parent.width
            height: 54

            Divider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }

            MaterialIcon {
                id: modeIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.modeInfo.icon
                font.pixelSize: 24
                color: Appearance.colors.primary
            }

            TextInput {
                id: input

                anchors.left: modeIcon.right
                anchors.leftMargin: Appearance.spacing.large
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Appearance.colors.text
                font.family: Appearance.font.family.sans
                font.pixelSize: 21
                selectByMouse: true
                selectionColor: Appearance.colors.primary
                selectedTextColor: Appearance.colors.primaryText
                clip: true
                cursorDelegate: Rectangle {
                    width: 2
                    color: Appearance.colors.primary

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: root.visible && input.activeFocus

                        PropertyAction {
                            value: 1
                        }
                        PauseAnimation {
                            duration: 530
                        }
                        PropertyAction {
                            value: 0
                        }
                        PauseAnimation {
                            duration: 530
                        }
                    }
                }

                Keys.onEscapePressed: DrawerState.close()
                Keys.onTabPressed: root.cycleMode(1)
                Keys.onBacktabPressed: root.cycleMode(-1)
                Keys.onReturnPressed: root.activate(root.currentIndex())
                Keys.onEnterPressed: root.activate(root.currentIndex())
                Keys.onUpPressed: root.view === "grid" ? grid.moveCurrentIndexUp() : list.decrementCurrentIndex()
                Keys.onDownPressed: root.view === "grid" ? grid.moveCurrentIndexDown() : list.incrementCurrentIndex()
                Keys.onPressed: event => {
                    // Di grid, panah kiri/kanan menggeser pilihan, bukan kursor teks
                    if (root.view === "grid" && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                        event.key === Qt.Key_Left ? grid.moveCurrentIndexLeft() : grid.moveCurrentIndexRight();
                        event.accepted = true;
                    } else if (root.mode === "clip" && event.key === Qt.Key_Delete) {
                        const r = root.results[list.currentIndex];
                        if (r)
                            Clipboard.remove(r.line);
                        event.accepted = true;
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    // Teks setelah prefix kosong: tampilkan petunjuk mode
                    visible: root.term === "" && (input.text === "" || input.text === root.modeInfo.prefix)
                    x: input.text === "" ? 0 : input.positionToRectangle(1).x + 6
                    text: root.modeInfo.hint
                    color: Appearance.colors.outline
                    font: input.font
                }
            }
        }

        // Judul bagian + detail item terpilih (untuk grid yang tanpa teks)
        Item {
            width: parent.width
            height: 16
            visible: !root.showEmpty

            Caption {
                anchors.left: parent.left
                text: root.sectionTitle
            }

            StyledText {
                anchors.right: parent.right
                width: parent.width / 2
                horizontalAlignment: Text.AlignRight
                visible: root.view === "grid"
                text: root.current?.title ?? ""
                color: Appearance.colors.primary
                font.family: Appearance.font.family.mono
                font.pixelSize: Appearance.font.size.small
                elide: Text.ElideMiddle
            }
        }

        // Daftar bernomor
        ListView {
            id: list

            width: parent.width
            height: Math.min(count, root.maxRows) * root.rowHeight
            visible: root.view === "list" && count > 0
            clip: true
            model: root.view === "list" ? root.results : []
            highlightFollowsCurrentItem: false
            boundsBehavior: Flickable.StopAtBounds
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            highlight: StyledRect {
                width: list.width
                height: root.rowHeight
                y: list.currentItem?.y ?? 0
                radius: Appearance.radius.normal
                color: Appearance.colors.surfaceContainerHigh

                Behavior on y {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
                }
            }

            populate: Transition {
                id: pop

                SequentialAnimation {
                    PropertyAction {
                        property: "opacity"
                        value: 0
                    }
                    PauseAnimation {
                        duration: Math.min(pop.ViewTransition.index, 8) * 14
                    }
                    Anim {
                        property: "opacity"
                        to: 1
                        duration: Appearance.anim.durations.small
                    }
                }
            }

            delegate: Item {
                id: row

                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                readonly property string kind: modelData.kind
                readonly property bool mono: kind === "calc" || kind === "run"

                width: ListView.view.width
                height: root.rowHeight

                // Nomor urut ala TE
                StyledText {
                    id: num

                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.padding.normal
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    text: String(row.index + 1).padStart(2, "0")
                    color: row.current ? Appearance.colors.primary : Appearance.colors.outline
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.small
                }

                Item {
                    id: glyph

                    anchors.left: num.right
                    anchors.leftMargin: Appearance.spacing.normal
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32

                    AppIcon {
                        anchors.centerIn: parent
                        visible: row.kind === "app"
                        icon: visible ? row.modelData.icon ?? "" : ""
                        lit: row.current
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: row.kind !== "app"
                        text: row.modelData.icon ?? ""
                        font.pixelSize: 22
                        fill: row.current ? 1 : 0
                        color: row.current ? Appearance.colors.primary : Appearance.colors.textDim
                    }
                }

                Column {
                    anchors.left: glyph.right
                    anchors.leftMargin: Appearance.spacing.large
                    anchors.right: enter.left
                    anchors.rightMargin: Appearance.spacing.normal
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        width: parent.width
                        text: row.modelData.title
                        color: Appearance.colors.text
                        font.pixelSize: row.kind === "calc" ? Appearance.font.size.large : Appearance.font.size.normal
                        font.family: row.mono ? Appearance.font.family.mono : Appearance.font.family.sans
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    StyledText {
                        width: parent.width
                        visible: text !== ""
                        text: row.modelData.subtitle ?? ""
                        color: Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                        elide: Text.ElideRight
                    }
                }

                MaterialIcon {
                    id: enter

                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.padding.normal
                    anchors.verticalCenter: parent.verticalCenter
                    text: "keyboard_return"
                    color: Appearance.colors.primary
                    opacity: row.current ? 1 : 0

                    transform: Translate {
                        x: row.current ? 0 : -6

                        Behavior on x {
                            Anim {
                                duration: Appearance.anim.durations.expressiveFast
                                easing.bezierCurve: Appearance.anim.curves.expressiveFast
                            }
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: mouse => {
                        if (hoverGuard.moved(row, mouse.x, mouse.y))
                            list.currentIndex = row.index;
                    }
                    onClicked: root.activate(row.index)
                }
            }
        }

        // Grid: aplikasi favorit, emoji, wallpaper
        GridView {
            id: grid

            width: root.cellW * root.gridCols
            height: Math.min(Math.ceil(count / root.gridCols), root.gridRows) * root.cellH
            visible: root.view === "grid" && count > 0
            clip: true
            model: root.view === "grid" ? root.results : []
            cellWidth: root.cellW
            cellHeight: root.cellH
            keyNavigationWraps: false
            highlightFollowsCurrentItem: false
            boundsBehavior: Flickable.StopAtBounds
            // Baris terpilih selalu kelihatan
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

            highlight: StyledRect {
                visible: root.mode !== "wall"
                width: grid.cellWidth
                height: grid.cellHeight
                x: grid.currentItem?.x ?? 0
                y: grid.currentItem?.y ?? 0
                radius: Appearance.radius.normal
                color: Appearance.colors.surfaceContainerHigh

                Behavior on x {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
                }
                Behavior on y {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFast
                        easing.bezierCurve: Appearance.anim.curves.expressiveFast
                    }
                }
            }

            populate: Transition {
                id: gridPop

                SequentialAnimation {
                    PropertyAction {
                        property: "scale"
                        value: 0.6
                    }
                    PropertyAction {
                        property: "opacity"
                        value: 0
                    }
                    PauseAnimation {
                        duration: Math.min(gridPop.ViewTransition.index, 20) * 12
                    }
                    ParallelAnimation {
                        Anim {
                            property: "opacity"
                            to: 1
                            duration: Appearance.anim.durations.small
                        }
                        Anim {
                            property: "scale"
                            to: 1
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveFast
                        }
                    }
                }
            }

            delegate: Item {
                id: cell

                required property var modelData
                required property int index
                readonly property bool current: GridView.isCurrentItem
                readonly property string kind: modelData.kind

                width: grid.cellWidth
                height: grid.cellHeight

                // Aplikasi: ikon + nama
                Column {
                    anchors.centerIn: parent
                    visible: cell.kind === "app"
                    spacing: Appearance.spacing.small

                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: cell.kind === "app" ? cell.modelData.icon ?? "" : ""
                        lit: cell.current
                        size: 44
                        scale: cell.current ? 1.08 : 1

                        Behavior on scale {
                            Anim {
                                duration: Appearance.anim.durations.expressiveFast
                                easing.bezierCurve: Appearance.anim.curves.expressiveFast
                            }
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: grid.cellWidth - Appearance.padding.normal * 2
                        horizontalAlignment: Text.AlignHCenter
                        text: cell.modelData.title
                        color: cell.current ? Appearance.colors.text : Appearance.colors.textDim
                        font.pixelSize: Appearance.font.size.small
                        elide: Text.ElideRight
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: cell.kind === "emoji"
                    text: cell.modelData.glyph ?? ""
                    font.pixelSize: cell.current ? 34 : 28

                    Behavior on font.pixelSize {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveFast
                        }
                    }
                }

                // Wallpaper: yang terpilih penuh, sisanya mengecil dan meredup
                StyledClippingRect {
                    anchors.centerIn: parent
                    visible: cell.kind === "wall"
                    width: (parent.width - Appearance.spacing.normal) * (cell.current ? 1 : 0.9)
                    height: (parent.height - Appearance.spacing.normal) * (cell.current ? 1 : 0.9)
                    radius: cell.current ? Appearance.radius.large : Appearance.radius.normal
                    color: Appearance.colors.surfaceContainerHigh
                    opacity: cell.current ? 1 : 0.55

                    Behavior on width {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                        }
                    }
                    Behavior on height {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFast
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefault
                        }
                    }
                    Behavior on radius {
                        Anim {}
                    }
                    Behavior on opacity {
                        Anim {}
                    }

                    Image {
                        anchors.fill: parent
                        source: cell.kind === "wall" && cell.modelData.path ? `file://${cell.modelData.path}` : ""
                        sourceSize: Qt.size(480, 320)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // Penanda wallpaper yang sedang dipakai
                    StyledRect {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Appearance.padding.small + 2
                        visible: cell.kind === "wall" && cell.modelData.path === Wallpaper.current
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: Appearance.colors.primary

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "check"
                            font.pixelSize: Appearance.font.size.larger
                            color: Appearance.colors.primaryText
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: mouse => {
                        if (hoverGuard.moved(cell, mouse.x, mouse.y))
                            grid.currentIndex = cell.index;
                    }
                    onClicked: root.activate(cell.index)
                }
            }
        }

        // Kalkulator: hasil sebagai angka dot-matrix besar
        Item {
            width: parent.width
            height: 132
            visible: root.view === "calc"

            Column {
                anchors.left: parent.left
                anchors.leftMargin: Appearance.padding.normal
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacing.small

                StyledText {
                    width: parent.width
                    text: root.term === "" ? "Contoh: 2^10, 15% * 80, (3+4)/2" : `${root.term} =`
                    color: Appearance.colors.textDim
                    font.family: Appearance.font.family.mono
                    font.pixelSize: Appearance.font.size.normal
                    elide: Text.ElideLeft
                }

                DisplayText {
                    width: parent.width
                    text: root.results[0]?.title ?? (root.term === "" ? "0" : "--")
                    color: root.results.length > 0 ? Appearance.colors.text : Appearance.colors.outline
                    font.pixelSize: 64
                    weight: 800
                    elide: Text.ElideLeft
                }
            }
        }

        // Kosong
        Column {
            width: parent.width
            visible: root.showEmpty
            spacing: Appearance.spacing.small
            topPadding: Appearance.spacing.huge
            bottomPadding: Appearance.spacing.huge

            DisplayText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "00"
                color: Appearance.colors.outline
                font.pixelSize: 48
            }

            Caption {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.mode === "clip" && !Clipboard.available ? "Install cliphist untuk riwayat clipboard" : root.mode === "clip" ? "Clipboard masih kosong" : root.mode === "wall" ? `Tidak ada gambar di ${Config.wallpaperDir}` : "Tidak ada hasil"
            }
        }

        // Petunjuk tombol
        Item {
            width: parent.width
            height: 28

            Divider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: Appearance.spacing.huge

                Hint {
                    visible: root.view !== "calc"
                    key: root.view === "grid" ? "↑↓←→" : "↑↓"
                    label: "Pilih"
                }
                Hint {
                    key: "↵"
                    label: ({
                            app: "Buka",
                            action: "Jalankan",
                            run: "Jalankan",
                            wall: "Pasang"
                        })[root.current?.kind] ?? "Salin"
                }
                Hint {
                    key: "Tab"
                    label: "Mode"
                }
                Hint {
                    visible: root.mode === "clip"
                    key: "Del"
                    label: "Hapus"
                }
            }

            Hint {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                key: "Esc"
                label: "Tutup"
            }
        }
    }
}
